# SmartStay Huésped - Project Overview

Flutter app for hotel guests. Manages reservations, check-ins, room access via NFC HCE.

## Core Stack
- **Framework**: Flutter
- **State Management**: Provider
- **Networking**: Dio / Http
- **Storage**: Secure Storage, Shared Preferences

## Project Structure
- `lib/models`: Data models (`ReservaHotel`, `Huesped`, `CredencialAcceso`, etc.)
- `lib/services/api/`: API services (Dio-based)
- `lib/services/auth_provider.dart`: Auth and session management
- `lib/services/api/nfc_hce_service.dart`: Dart-side HCE control via MethodChannel
- `lib/screens`: UI screens
- `lib/widgets/apertura_nfc_modal.dart`: NFC door opening modal with debug panel

## NFC HCE Connection Protocol (App ↔ ESP32 Lock)

### Architecture
```
[Flutter App] → MethodChannel → [Android HCE Service] ← NFC RF ← [PN532 on ESP32]
```

### Hardware (Lock Side)
- **Reader**: Adafruit PN532 (I2C: SDA=GPIO19, SCL=GPIO20)
- **Relay**: GPIO 43 (HIGH=open, LOW=closed)
- **Poll**: Every 1 second via lv_timer

### AID (Application Identifier)
```
F0010203040506
```
Both sides MUST use this exact AID. Registered in:
- App: `android/app/src/main/res/xml/apduservice.xml`
- ESP32: hardcoded in `nfc.cpp` SELECT command

### APDU Exchange Sequence

1. **ESP32 detects phone** → ISO 14443-A, SAK=0x20 (identifies ISO-DEP/HCE device)
2. **ESP32 sends RATS** (InAtr) → Android responds ATS automatically
3. **ESP32 sends SELECT AID**:
   ```
   00 A4 04 00 07 F0 01 02 03 04 05 06 00
   │  │  │  │  │  └── AID (7 bytes) ───┘  │
   CLA INS P1 P2 Lc                       Le
   ```
4. **App responds**: JSON bytes + Status Word `90 00`

### JSON Payload (CRITICAL — exact format)
```json
{"credencial":{"pin":"142820"}}
```
- ESP32 parses: `doc["credencial"]["pin"]`
- Any key variation = silent failure (null pointer)
- Max 255 bytes total (PN532 buffer limit)
- Current payload ~36 bytes — well within limit

### ESP32 Validation After Receiving PIN
1. Finds PIN in `s_creds[]` array (loaded from ThingsBoard)
2. Checks `now >= activacion && now <= expiracion` (UTC-4, Dominican Republic)
3. If NTP not synced → validates PIN without time check (contingency)
4. Valid → `lock_unlock()` → `digitalWrite(43, HIGH)` → relay opens

### App-Side Implementation Files

| Layer | File | Role |
|-------|------|------|
| Native Service | `android/.../SmartStayHceService.kt` | HostApduService, responds to SELECT AID with JSON |
| Platform Bridge | `android/.../MainActivity.kt` | MethodChannel `smartstay/nfc_hce` + EventChannel |
| Event Stream | `android/.../ApduEventStreamHandler.kt` | Pushes APDU events to Flutter |
| Dart Service | `lib/services/api/nfc_hce_service.dart` | `startEmulation()`, `stopEmulation()`, `getStatus()` |
| UI Modal | `lib/widgets/apertura_nfc_modal.dart` | Wakelock, animations, APDU debug panel |
| Options | `lib/widgets/apertura_opciones_sheet.dart` | Builds `{"credencial":{"pin": pinAcceso}}` from room data |

### Data Flow
```
Habitacion.pinAcceso or Reserva.pinAcceso
  → AperturaOpcionesSheet builds {"credencial":{"pin":"XXXXXX"}}
  → NfcHceService.startEmulation(credentialData)
  → MethodChannel "startHce" → SharedPreferences "hce_data"
  → SmartStayHceService.processCommandApdu() reads from prefs
  → Returns JSON + 0x9000 to PN532
  → ESP32 parses PIN → validates → opens relay
```

### SharedPreferences Keys (SmartStayPrefs)
- `hce_data`: JSON string to respond with
- `hce_active`: boolean — service only responds when true
- `hce_last_apdu`: last received APDU hex
- `hce_last_apdu_ts`: timestamp millis
- `hce_apdu_count`: total APDUs received

### Android Config
- `AndroidManifest.xml`: NFC permission, HCE feature (required=false), service declaration
- `apduservice.xml`: AID filters `F0010203040506` + NDEF fallback `D276000085010100`, category "other", no device unlock required
- `strings.xml`: Service and AID group descriptions

### Requirements for Connection to Work
1. Phone NFC ON + screen awake
2. `hce_active = true` in SharedPreferences
3. `hce_data` contains valid JSON with `credencial.pin`
4. PIN exists in ESP32's ThingsBoard credential list
5. PIN within valid time window (activacion ≤ now ≤ expiracion)
6. Phone held within 4cm of PN532 antenna for ~200ms

### Debug (ESP32 Serial Log)
| Log | Meaning |
|-----|---------|
| `[NFC] SAK: 0x20` | Phone detected |
| `[NFC] ISO-DEP activado` | RATS/ATS OK |
| `[NFC] HCE respuesta (36 bytes)` | App responded |
| `[NFC] PIN extraído via nfc_hce` | JSON parsed |
| `[Creds] Acceso concedido` | PIN valid, door opening |
| `[NFC] InAtr: command timeout` | Phone moved away too fast |
| `[NFC] ERROR: SELECT fallido` | AID not registered in app |
| `[Creds] Denegado: expirado` | PIN expired |

### Common Issues
- **Wrong JSON format**: Must be exactly `{"credencial":{"pin":"..."}}` — no extra nesting
- **PIN "000000"**: Demo fallback used when credentialData is null (fixed in apertura_opciones_sheet)
- **HCE inactive**: Service started but `hce_active=false` in prefs
- **Screen off**: Most Android devices won't respond to NFC HCE with screen off
- **Multiple HCE apps**: If another app claims same AID, Android shows chooser dialog
