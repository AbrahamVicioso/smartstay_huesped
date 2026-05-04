/**
 * @file nfc.cpp
 * @brief Implementación NFC — PN532 + autorización por UID
 */

#include "nfc.h"
#include "../config/pins.h"
#include <Wire.h>

static Adafruit_PN532 nfc(NFC_SDA, NFC_SCL);

static char authorized_uid[25] = "";

bool nfc_init(void)
{
    nfc.begin();

    uint32_t versiondata = nfc.getFirmwareVersion();
    if (!versiondata) {
        Serial.println("[NFC] ERROR: Módulo PN532 no encontrado");
        return false;
    }

    Serial.printf("[NFC] PN5%02X firmware %d.%d\n",
                  (versiondata >> 24) & 0xFF,
                  (versiondata >> 16) & 0xFF,
                  (versiondata >>  8) & 0xFF);

    nfc.SAMConfig();
    Serial.println("[NFC] Lector PN532 listo");
    return true;
}

bool nfc_read_tag(NfcTag* tag)
{
    if (!tag) return false;

    uint8_t uid[NFC_UID_MAX_LENGTH] = {0};
    uint8_t uidLength = 0;

    bool success = nfc.readPassiveTargetID(PN532_MIFARE_ISO14443A,
                                            uid, &uidLength, 20);

    if (!success) {
        tag->valid = false;
        return false;
    }

    tag->uidLength = (uint8_t)min((int)uidLength, (int)NFC_UID_MAX_LENGTH);
    memcpy(tag->uid, uid, tag->uidLength);
    tag->sak   = nfc._lastSAK;
    tag->valid = true;

    Serial.printf("[NFC] Detectado — UID: ");
    nfc_print_uid(uid, uidLength);
    Serial.printf("[NFC] SAK: 0x%02X (%s)\n", tag->sak,
        (tag->sak == 0x20 || tag->sak == 0x28) ? "ISO-DEP/HCE" :
        (tag->sak == 0x08)                      ? "MIFARE Classic 1K" :
        (tag->sak == 0x18)                      ? "MIFARE Classic 4K" :
        (tag->sak == 0x00)                      ? "MIFARE Ultralight" : "Desconocido");

    return true;
}

void nfc_set_authorized_uid(const char* uid_hex)
{
    if (!uid_hex) {
        authorized_uid[0] = '\0';
        return;
    }
    strncpy(authorized_uid, uid_hex, sizeof(authorized_uid) - 1);
    authorized_uid[sizeof(authorized_uid) - 1] = '\0';

    for (int i = 0; authorized_uid[i]; i++) {
        if (authorized_uid[i] >= 'a' && authorized_uid[i] <= 'f')
            authorized_uid[i] -= 32;
    }

    if (strlen(authorized_uid) == 0) {
        Serial.println("[NFC] UID autorizado: ANY (acepta todas)");
    } else {
        Serial.printf("[NFC] UID autorizado: %s\n", authorized_uid);
    }
}

bool nfc_is_authorized(const NfcTag* tag)
{
    if (!tag || !tag->valid) return false;

    if (strlen(authorized_uid) == 0) return false;

    String tagStr = "";
    for (int i = 0; i < tag->uidLength; i++) {
        if (tag->uid[i] < 0x10) tagStr += "0";
        tagStr += String(tag->uid[i], HEX);
    }
    tagStr.toUpperCase();

    String authStr = String(authorized_uid);
    authStr.replace(":", "");
    authStr.replace(" ", "");
    authStr.replace("-", "");
    authStr.toUpperCase();

    bool authorized = (tagStr == authStr);
    Serial.printf("[NFC] UID leído: %s  Autorizado: %s  Resultado: %s\n",
                  tagStr.c_str(), authStr.c_str(),
                  authorized ? "ACEPTADO" : "RECHAZADO");
    return authorized;
}

String nfc_uid_to_string(const NfcTag* tag)
{
    String result = "";
    for (int i = 0; i < tag->uidLength; i++) {
        if (i > 0) result += ":";
        if (tag->uid[i] < 0x10) result += "0";
        result += String(tag->uid[i], HEX);
    }
    result.toUpperCase();
    return result;
}

void nfc_print_uid(uint8_t* uid, uint8_t uidLength)
{
    for (uint8_t i = 0; i < uidLength; i++) {
        if (i > 0) Serial.print(":");
        if (uid[i] < 0x10) Serial.print("0");
        Serial.print(uid[i], HEX);
    }
    Serial.println();
}

// ────────────────────────────────────────────────────────────
//  Activación ISO-DEP y lectura HCE (todo en una función)
// ────────────────────────────────────────────────────────────

// Flujo PN532 correcto:
// 1. readPassiveTargetID → detecta target y lo selecciona
// 2. InAtr (0x50) → envía RATS al target, establece canal ISO-14443-4
// 3. inDataExchange → envía SELECT AID y recibe JSON
// NOTA: No usar activateSync() entre InAtr e inDataExchange —
//       el canal ISO-DEP ya está activo después de InAtr.
bool nfc_read_hce_payload(char* buffer, uint16_t maxLen)
{
    if (!buffer || maxLen < 2) return false;

    uint8_t aid[] = HCE_AID;
    const uint8_t aidLen = sizeof(aid);

    // Paso 1: SELECT AID (envía RATS implícitamente si es necesario)
    // Formato ISO 7816-4 SELECT FILE:
    // CLA INS P1 P2 Lc [AID] Le
    // 00  A4  04 00 LL [AID] 00
    uint8_t cmd[6 + aidLen];
    cmd[0] = 0x00;
    cmd[1] = 0xA4;
    cmd[2] = 0x04;
    cmd[3] = 0x00;
    cmd[4] = aidLen;
    memcpy(&cmd[5], aid, aidLen);
    cmd[5 + aidLen] = 0x00;

    Serial.printf("[NFC] Enviando SELECT AID (%d bytes)...\n", 5 + aidLen + 1);
    nfc.PrintHex(cmd, 5 + aidLen + 1);

    // Enviar comando y esperar ACK
    uint8_t response[255];
    uint8_t respLen = sizeof(response);

    if (!nfc.sendCommandCheckAck(cmd, 5 + aidLen + 1, 500)) {
        Serial.println("[NFC] SELECT: timeout en ACK");
        return false;
    }

    // Leer respuesta: [ACK(2)][preamble(2)][LEN][LCS][TFI=D5][cmd=51][Err][Tg][ATS...]
    // Estructura PN532 I2C frame: 0x7F 0xBA [preamble][startcode][LEN][LCS][DATA][DCS][postamble]
    // Para InAtr response (0x50→0x51): DATA = D5 51 [Err] [Tg] [ATS...]
    const uint8_t FRAME_SIZE = 12;
    uint8_t frame[FRAME_SIZE];
    Wire.requestFrom((uint8_t)PN532_I2C_ADDRESS, FRAME_SIZE);

    uint8_t avail = Wire.available();
    Serial.printf("[NFC] PN532 I2C bytes disponibles: %d\n", avail);

    if (avail < FRAME_SIZE) {
        Serial.printf("[NFC] Respuesta incompleta: %d/%d bytes\n", avail, FRAME_SIZE);
        while (Wire.available()) Wire.read();
        return false;
    }

    for (int i = 0; i < FRAME_SIZE; i++) {
        frame[i] = Wire.read();
    }

    // Imprimir frame raw para debug
    Serial.printf("[NFC] Frame raw: ");
    nfc.PrintHex(frame, FRAME_SIZE);

    // Parsear frame PN532
    // Byte 0-1: ACK 0x00 0xFF (en modo normal) o 0x7F 0xBA
    // Byte 2-3: preamble + start code (0xFF 0xFF)
    // Byte 4: LEN (longitud de datos = TFI+comando+params+chksum)
    // Byte 5: DCS
    // Byte 6: TFI (0xD5)
    // Byte 7: response code (0x51 = InAtr response)
    // Byte 8: error code (0x00 = OK)
    // Byte 9: Tg (target)
    // Byte 10+: ATS o datos adicionales
    // Byte 11: postamble (0x00)

    uint8_t pn532_ack1 = frame[0];
    uint8_t pn532_ack2 = frame[1];
    uint8_t tfi        = frame[6];
    uint8_t cmd_resp  = frame[7];
    uint8_t err_code  = frame[8];

    Serial.printf("[NFC] ACK: %02X %02X | TFI: %02X | Cmd: %02X | Err: %02X\n",
                  pn532_ack1, pn532_ack2, tfi, cmd_resp, err_code);

    // Verificar que sea una respuesta de SELECT (0xA4→0x61 o 0x90)
    // Después de SELECT AID exitoso, el status es:
    // SW1=0x90 SW2=0x00 (comando exitoso) o
    // SW1=0x61 SW2=0xx (datos disponibles)
    // Los datos del PN532 vendrán en los bytes siguientes

    if (cmd_resp != 0x61 && cmd_resp != 0x90) {
        Serial.printf("[NFC] Respuesta inesperada SELECT: %02X\n", cmd_resp);
        return false;
    }

    // Leer los datos reales (puede venir en seguida otro frame con el JSON)
    uint8_t jsonFrame[255];
    uint8_t jsonLen = 0;

    // Limpiar buffer Wire restante primero
    while (Wire.available()) Wire.read();

    // Hacer inDataExchange para obtener los datos
    // Esta vez sin activar ISO-DEP de nuevo
    uint8_t getResponse[] = { 0x00, 0xC0, 0x00, 0x00, 0x00 };

    if (nfc.sendCommandCheckAck(getResponse, 5, 500)) {
        Wire.requestFrom((uint8_t)PN532_I2C_ADDRESS, 64);
        uint8_t gr_avail = Wire.available();
        Serial.printf("[NFC] GET RESPONSE: %d bytes disponibles\n", gr_avail);

        if (gr_avail > 4) {
            for (int i = 0; i < gr_avail && jsonLen < 250; i++) {
                uint8_t b = Wire.read();
                jsonFrame[jsonLen++] = b;
            }
        }
        while (Wire.available()) Wire.read();
    }

    // Intentar directamente con inDataExchange (reintento)
    respLen = sizeof(response);
    bool ok = nfc.inDataExchange(cmd, 5 + aidLen + 1, response, &respLen);

    if (ok) {
        Serial.printf("[NFC] inDataExchange OK (%d bytes): ", respLen);
        nfc.PrintHexChar(response, respLen);

        if (respLen >= 2) {
            uint8_t sw1 = response[respLen - 2];
            uint8_t sw2 = response[respLen - 1];
            Serial.printf("[NFC] Status: %02X %02X\n", sw1, sw2);

            if (sw1 == 0x90 && sw2 == 0x00) {
                uint16_t jsonDataLen = respLen - 2;
                uint16_t copyLen = (jsonDataLen < maxLen - 1) ? jsonDataLen : (maxLen - 1);
                memcpy(buffer, response, copyLen);
                buffer[copyLen] = '\0';
                Serial.printf("[NFC] HCE payload recibido (%u bytes)\n", copyLen);
                return true;
            } else {
                Serial.printf("[NFC] Status inválido: %02X %02X\n", sw1, sw2);
            }
        }
    } else {
        Serial.println("[NFC] inDataExchange falló");
        nfc.PrintHexChar(response, min(respLen, (uint8_t)8));
    }

    return false;
}

bool nfc_read_json_payload(const NfcTag* tag, char* buffer, uint16_t maxLen)
{
    if (!tag || !tag->valid || !buffer || maxLen < 2) return false;

    uint8_t ndefKey[6] = { 0xD3, 0xF7, 0xD3, 0xF7, 0xD3, 0xF7 };

    uint16_t bufPos    = 0;
    bool     started   = false;
    int      depth     = 0;

    for (uint8_t block = 4; block < 64 && bufPos < (uint16_t)(maxLen - 1); block++) {

        if ((block % 4) == 3) continue;

        if ((block % 4) == 0) {
            bool auth = nfc.mifareclassic_AuthenticateBlock(
                (uint8_t*)tag->uid, tag->uidLength,
                block, 0, ndefKey);
            if (!auth) {
                Serial.printf("[NFC] Auth falló en bloque %d\n", block);
                break;
            }
        }

        uint8_t blockData[16];
        if (!nfc.mifareclassic_ReadDataBlock(block, blockData)) {
            Serial.printf("[NFC] Read falló en bloque %d\n", block);
            break;
        }

        for (int i = 0; i < 16 && bufPos < (uint16_t)(maxLen - 1); i++) {
            uint8_t c = blockData[i];

            if (!started) {
                if (c == '{') {
                    started = true;
                    depth   = 1;
                    buffer[bufPos++] = c;
                }
                continue;
            }

            if      (c == '{') depth++;
            else if (c == '}') depth--;

            buffer[bufPos++] = c;

            if (depth == 0) {
                buffer[bufPos] = '\0';
                Serial.printf("[NFC] JSON extraído (%u bytes)\n", bufPos);
                return true;
            }
        }
    }

    return false;
}