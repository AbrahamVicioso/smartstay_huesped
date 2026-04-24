import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class HceStatus {
  final bool isActive;
  final bool hasData;
  final String dataPreview;
  final String lastApduReceived;
  final int lastApduTimestamp;
  final int apduCount;

  const HceStatus({
    required this.isActive,
    required this.hasData,
    required this.dataPreview,
    required this.lastApduReceived,
    required this.lastApduTimestamp,
    required this.apduCount,
  });
}

class ApduEvent {
  final String apdu;
  final String response;
  final DateTime timestamp;

  ApduEvent({
    required this.apdu,
    required this.response,
    required this.timestamp,
  });
}

class NfcHceService {
  static const MethodChannel _channel = MethodChannel('smartstay/nfc_hce');
  static const EventChannel _eventChannel =
      EventChannel('smartstay/nfc_hce_events');

  static Stream<ApduEvent>? _apduStream;

  static Stream<ApduEvent> get apduEvents {
    _apduStream ??= _eventChannel.receiveBroadcastStream().map((event) {
      final map = Map<String, dynamic>.from(event as Map);
      return ApduEvent(
        apdu: map['apdu'] as String,
        response: map['response'] as String,
        timestamp:
            DateTime.fromMillisecondsSinceEpoch(map['timestamp'] as int),
      );
    });
    return _apduStream!;
  }

  static Future<bool> isSupported() async {
    try {
      final bool? isEnabled = await _channel.invokeMethod('isNfcEnabled');
      return isEnabled ?? false;
    } catch (e) {
      debugPrint('Error verificando estado NFC nativo: $e');
      return false;
    }
  }

  static Future<bool> startEmulation(Map<String, dynamic> credentialData) async {
    try {
      final String jsonData = jsonEncode(credentialData);
      final bool? success =
          await _channel.invokeMethod('startHce', {'data': jsonData});
      debugPrint('NFC HCE Nativo iniciado: $success');
      return success ?? false;
    } catch (e) {
      debugPrint('Error iniciando NFC HCE Nativo: $e');
      return false;
    }
  }

  static Future<void> stopEmulation() async {
    try {
      await _channel.invokeMethod('stopHce');
      debugPrint('NFC HCE Nativo detenido');
    } catch (e) {
      debugPrint('Error deteniendo NFC HCE Nativo: $e');
    }
  }

  static Future<HceStatus?> getStatus() async {
    try {
      final result =
          await _channel.invokeMethod<Map>('getHceStatus');
      if (result == null) return null;
      return HceStatus(
        isActive: result['isActive'] as bool? ?? false,
        hasData: result['hasData'] as bool? ?? false,
        dataPreview: result['dataPreview'] as String? ?? '',
        lastApduReceived: result['lastApduReceived'] as String? ?? '',
        lastApduTimestamp: (result['lastApduTimestamp'] as int?) ?? 0,
        apduCount: (result['apduCount'] as int?) ?? 0,
      );
    } catch (e) {
      debugPrint('Error leyendo HCE status: $e');
      return null;
    }
  }
}
