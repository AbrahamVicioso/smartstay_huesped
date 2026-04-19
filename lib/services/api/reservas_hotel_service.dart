// lib/services/api/reservas_hotel_service.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../../models/reserva_hotel.dart';

class ReservasHotelService {
  
  Future<List<ReservaHotel>> getReservasByUserId(
    String userId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse('${ApiConfig.reservasBaseUrl}/user/$userId');
      debugPrint('[ReservasHotelService] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('[ReservasHotelService] Status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((j) => ReservaHotel.fromJson(j)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ReservasHotelService] Error: $e');
      return [];
    }
  }

  Future<Map<String, dynamic>> abrirPuerta(
    int reservaId, {
    String? pin,
    String? token,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.reservasBaseUrl}/$reservaId/unlock-door${pin != null ? '?pin=$pin' : ''}',
      );
      debugPrint('[ReservasHotelService] POST $uri');

      final response = await http.post(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('[ReservasHotelService] unlock status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'exitoso': true,
          'mensaje': body['message'] ?? 'Puerta abierta exitosamente',
        };
      } else {
        final body = response.body.isNotEmpty ? jsonDecode(response.body) : {};
        return {
          'exitoso': false,
          'mensaje': body['error'] ?? body['message'] ?? 'Error ${response.statusCode}',
        };
      }
    } catch (e) {
      debugPrint('[ReservasHotelService] Error abrirPuerta: $e');
      return {'exitoso': false, 'mensaje': 'Error de conexión: $e'};
    }
  }

  Future<Map<String, dynamic>?> getCredenciales(
    int reservaId, {
    String? token,
  }) async {
    try {
      final uri = Uri.parse(
        '${ApiConfig.reservasBaseUrl}/me/reserva/$reservaId/credenciales',
      );
      debugPrint('[ReservasHotelService] GET $uri');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(const Duration(seconds: 15));

      debugPrint('[ReservasHotelService] credenciales status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        if (data.isNotEmpty) {
          // Tomar la primera credencial activa
          final credId = data.firstWhere(
            (c) => c['estaActiva'] == true,
            orElse: () => data.first,
          );
          return credId as Map<String, dynamic>;
        }
      }
      return null;
    } catch (e) {
      debugPrint('[ReservasHotelService] Error getCredenciales: $e');
      return null;
    }
  }
}