import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/reserva_api.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';
import 'huespedes_service.dart';

class ReservasService {
  static final ReservasService _instance = ReservasService._internal();
  factory ReservasService() => _instance;
  ReservasService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();
  final _huespedesService = HuespedesService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.reservasBaseUrl,
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    _dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final accessToken = await _storage.getAccessToken();
          if (accessToken != null) {
            final tokenType = await _storage.getTokenType() ?? 'Bearer';
            options.headers['Authorization'] = '$tokenType $accessToken';
          }
          return handler.next(options);
        },
      ),
    );

    if (kDebugMode) {
      _dio.interceptors.add(LogInterceptor(requestBody: true, responseBody: true));
    }
  }


  Future<List<ReservaApi>> getMisReservas() async {
    try {
      final response = await _dio.get('/me');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['\$values'] ?? []);
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('[ReservasService] Error en getMisReservas: $e');
      return [];
    }
  }


  Future<List<ReservaApi>> getByHuespedId(int huespedId) async {
  
    try {
      final response = await _dio.get('/huesped/$huespedId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['\$values'] ?? []);
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      return [];
    }
  }

  /// Método unificado para abrir puertas (IoT)
  Future<Map<String, dynamic>> abrirPuerta(int reservaId, {String? pin}) async {
    try {
      final response = await _dio.post(
        '/$reservaId/unlock-door',
        queryParameters: pin != null ? {'pin': pin} : null,
      );
      return {
        'exitoso': response.statusCode == 200,
        'mensaje': response.data['message'] ?? 'Puerta abierta correctamente',
      };
    } catch (e) {
      return {'exitoso': false, 'mensaje': 'Error al intentar abrir la puerta'};
    }
  }

  Future<Map<String, dynamic>?> getCredenciales(int reservaId) async {
    try {
      final response = await _dio.get('/me/reserva/$reservaId/credenciales');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List ? response.data : (response.data['\$values'] ?? []);
        if (data.isNotEmpty) return data.first;
      }
      return null;
    } catch (e) {
      return null;
    }
  }


  Future<ReservaApi?> validarReserva(String numeroReserva, String documento) async {
    try {
      final response = await _dio.get('/validar', queryParameters: {
        'numeroReserva': numeroReserva,
        'documento': documento,
      });
      if (response.statusCode == 200) {
        return ReservaApi.fromJson(response.data);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
  Future<List<ReservaApi>> getReservasByUserId(String userId, {String? token}) async {
    debugPrint('[ReservasService] Redirigiendo consulta de reservas a /me');
    return getMisReservas();
  }
}