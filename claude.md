# SmartStay Huésped - Project Overview

This is a Flutter application designed for hotel guests (SmartStay). It manages reservations, check-ins, and room access.

## Core Stack
- **Framework**: Flutter
- **State Management**: Provider
- **Networking**: Dio / Http
- **Storage**: Secure Storage, Shared Preferences

## Project Structure
- `lib/models`: Data models like `ReservaHotel`, `Huesped`, etc.
- `lib/services`:
    - `api/`: Lower-level API services (Dio).
    - `auth_provider.dart`: Authentication and session management.
    - `reservas_hotel_provider.dart`: Logic for hotel reservations and door opening.
    - `secure_storage_service.dart`: Encryption-backed local storage.
- `lib/screens`: UI screens including:
    - `home_screen.dart`: Main dashboard.
    - `reserva_detalle_screen.dart`: Detailed view of a reservation with room info and door opening actions.
    - `habitacion_detalle_screen.dart`: Room-specific details.

## NFC HCE Implementation Goal
The project is moving towards supporting **Host Card Emulation (HCE)** for Android devices. This will allow guests to use their phones as digital keys by emulating an NFC card that the electronic lock can read.

### Technical Requirements
- **Plugin**: `nfc_host_card_emulation`
- **AID (Application ID)**: `F0010203040506`
- **Workflow**:
    1. Verify HCE support on the device.
    2. Retrieve JSON credential from the backend for the active reservation.
    3. Initialize the HCE service with the AID and JSON payload.
    4. The lock reads the JSON from the phone to authorize entry.

## Ongoing Tasks
- [ ] Add `nfc_host_card_emulation` to `pubspec.yaml`.
- [ ] Configure `AndroidManifest.xml` and `apduservice.xml` in the Android folder.
- [ ] Implement `NfcHceService` in Dart to manage the emulation lifecycle.
- [ ] Integrate HCE controls into `ReservaDetalleScreen` or a dedicated "Digital Key" UI.
