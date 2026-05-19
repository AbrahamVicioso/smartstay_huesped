# Instrucciones para la IA del Proyecto Cerradura ESP32

## Quién soy
Soy la app Android "SmartStay Huésped" (Flutter). Emulo una tarjeta NFC usando Host Card Emulation (HCE). Cuando el huésped acerca su teléfono al lector PN532 de la cerradura, yo respondo con un JSON que contiene el PIN de acceso.

---

## Protocolo de Conexión NFC HCE

### AID (Application Identifier) — AMBOS DEBEMOS USAR ESTE
```
F0010203040506
```
- Es de 7 bytes
- Categoría: "other" (no es pago)
- Si tu ESP32 envía SELECT con otro AID, Android NO me lo va a rutear y no recibiré nada

### Comando SELECT AID que debes enviar (exacto)
```
00 A4 04 00 07 F0 01 02 03 04 05 06 00
```
Desglose:
| Byte | Valor | Significado |
|------|-------|-------------|
| CLA | 00 | Clase estándar |
| INS | A4 | SELECT |
| P1 | 04 | Selección por nombre (AID) |
| P2 | 00 | Primera ocurrencia |
| Lc | 07 | Longitud del AID = 7 bytes |
| AID | F0 01 02 03 04 05 06 | El AID del sistema |
| Le | 00 | Respuesta de cualquier longitud |

### Mi respuesta (lo que recibirás del teléfono)
```
[JSON bytes UTF-8] [90] [00]
```
- Los últimos 2 bytes SIEMPRE son `90 00` (Status Word = SUCCESS)
- Todo lo anterior es JSON puro en UTF-8

### Formato EXACTO del JSON que envío
```json
{"credencial":{"pin":"142820"}}
```

**IMPORTANTE — parsea exactamente así:**
```c
doc["credencial"]["pin"]  // → "142820" (string de 6 dígitos)
```

- NO es `doc["pin"]`
- NO es `doc["credential"]["pin"]`
- NO es `doc["credencial"]["codigo"]`
- ES: `doc["credencial"]["pin"]` — exactamente esas keys

### Tamaño del payload
- JSON típico: ~36 bytes (ej: `{"credencial":{"pin":"142820"}}` = 33 bytes)
- Máximo posible: < 100 bytes
- Tu buffer de 255 bytes es más que suficiente

---

## Secuencia Completa que Debes Implementar

```
1. Poll NFC (readPassiveTargetID) cada 1 segundo
2. Si detectas target → revisar SAK
3. SAK == 0x20 o 0x28 → es smartphone HCE → continuar
   SAK == 0x08 o 0x18 → es MIFARE Classic → otro flujo
4. Enviar InAtr (RATS) → esperar ATS del teléfono (automático)
5. Enviar SELECT AID (el comando de arriba)
6. Recibir respuesta → verificar últimos 2 bytes == 90 00
7. Extraer JSON (todo menos últimos 2 bytes)
8. Parsear JSON → obtener doc["credencial"]["pin"]
9. Validar PIN contra lista de credenciales
10. Si válido → abrir relay
```

---

## Lo que YO hago de mi lado (para que sepas)

1. Usuario abre la app → va a su habitación → toca "Abrir con NFC"
2. App autentica con biométrico (huella/cara)
3. App toma el PIN de la habitación y construye: `{"credencial":{"pin":"XXXXXX"}}`
4. App activa HCE: guarda el JSON en SharedPreferences y marca `hce_active=true`
5. Android registra mi servicio con AID `F0010203040506`
6. **Teléfono queda esperando** — no hace nada hasta que TU lector envíe SELECT AID
7. Cuando recibes mi respuesta con `9000`, yo detecto éxito y muestro "Puerta Abierta"

---

## Condiciones para que Funcione

### Del lado del teléfono (mi responsabilidad)
- [x] NFC activado en ajustes del teléfono
- [x] Pantalla encendida (HCE no funciona con pantalla apagada en mayoría de dispositivos)
- [x] App abierta con modal NFC activo (wakelock previene apagado de pantalla)
- [x] JSON con PIN válido cargado en el servicio HCE

### Del lado de la cerradura (tu responsabilidad)
- [ ] PN532 en modo ISO 14443A
- [ ] Detectar SAK 0x20 para rutear a flujo HCE
- [ ] Enviar InAtr antes del SELECT (establece canal ISO-DEP)
- [ ] SELECT AID con los 7 bytes exactos: `F0010203040506`
- [ ] Parsear `doc["credencial"]["pin"]` del JSON
- [ ] Validar PIN contra credenciales activas
- [ ] Verificar ventana temporal (activación ≤ ahora ≤ expiración)

---

## Fallback NDEF (opcional)

Si el SELECT con AID `F0010203040506` falla, puedes intentar con AID NDEF estándar:
```
D276000085010100
```
Son 8 bytes (no 7). Yo también registro este AID como fallback. Pero el primario debería funcionar siempre.

---

## Errores Comunes y Diagnóstico

| Síntoma | Causa probable | Solución |
|---------|---------------|----------|
| No detecta teléfono | NFC apagado o teléfono muy lejos | Acercar a <4cm, verificar NFC on |
| SAK no es 0x20 | Estás leyendo una tarjeta, no un teléfono | Verificar SAK routing |
| InAtr timeout | Teléfono se movió antes de completar handshake | Mantener teléfono quieto ~500ms |
| SELECT falla (no respuesta) | AID incorrecto o app no tiene HCE activo | Verificar AID exacto |
| Respuesta sin 9000 | App respondió con error (6A82) | HCE inactivo o sin datos cargados |
| JSON vacío o malformado | Bug en app | Verificar que `hce_data` en prefs no sea null |
| PIN no encontrado en lista | PIN no existe en ThingsBoard | Sincronizar credenciales |
| PIN expirado | Ventana temporal pasó | Verificar fechas en ThingsBoard |

---

## Resumen en Una Línea

**Tú envías `00A4040007F001020304050600` → Yo respondo `{"credencial":{"pin":"XXXXXX"}}` + `9000` → Tú validas el PIN → Abres la puerta.**

---

## Versión del protocolo
- v1.0 — Mayo 2025
- Sin encriptación adicional (el canal NFC es de corto alcance ~4cm)
- Sin challenge-response (solo PIN directo)
- Futuro: posible HMAC o firma para anti-replay
