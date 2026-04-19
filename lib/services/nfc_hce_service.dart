import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class NfcHceService {
  static const MethodChannel _channel = MethodChannel('smartstay/nfc_hce');

  /// Verifica si el dispositivo tiene NFC activado
  static Future<bool> isSupported() async {
    try {
      final bool? isEnabled = await _channel.invokeMethod('isNfcEnabled');
      return isEnabled ?? false;
    } catch (e) {
      debugPrint('Error verificando estado NFC nativo: $e');
      return false;
    }
  }

  /// Inicia la emulación con los datos de la credencial llamando al código nativo
  static Future<bool> startEmulation(Map<String, dynamic> credentialData) async {
    try {
      String jsonData = jsonEncode(credentialData);
      
      final bool? success = await _channel.invokeMethod('startHce', {
        'data': jsonData,
      });
      
      debugPrint('NFC HCE Nativo iniciado: $success');
      return success ?? false;
    } catch (e) {
      debugPrint('Error iniciando NFC HCE Nativo: $e');
      return false;
    }
  }

  /// Detiene la emulación limpiando el estado en el código nativo
  static Future<void> stopEmulation() async {
    try {
      await _channel.invokeMethod('stopHce');
      debugPrint('NFC HCE Nativo detenido');
    } catch (e) {
      debugPrint('Error deteniendo NFC HCE Nativo: $e');
    }
  }
}
