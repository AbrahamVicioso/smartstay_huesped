import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../models/api/reserva_actividad.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';

class ReservasActividadesService {
  static final ReservasActividadesService _instance = ReservasActividadesService._internal();
  factory ReservasActividadesService() => _instance;
  ReservasActividadesService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

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

  
  
  Future<List<ReservaActividadApi>> getMisActividades(int huespedId) async {
    try {
      debugPrint('[ActividadesService] Obteniendo actividades para huespedId: $huespedId');

      final response = await _dio.get('/ReservasActividades/me');

      debugPrint('[ActividadesService] Response status: ${response.statusCode}');
      debugPrint('[ActividadesService] Response data type: ${response.data.runtimeType}');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['\$values'] ?? []);
        
        debugPrint('[ActividadesService] Actividades encontradas: ${data.length}');
        
        final actividades = data.map((json) => ReservaActividadApi.fromJson(json)).toList();
        
        
        for (var act in actividades) {
          debugPrint('[ActividadesService] Reserva ${act.reservaActividadId} - Estado: ${act.estado}');
        }
        
        return actividades;
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[ActividadesService] Fetch Error: ${e.message}');
      debugPrint('[ActividadesService] Response: ${e.response?.data}');
      return [];
    }
  }

  Future<ReservaActividadApi?> crearReservaActividad({
    required int actividadId,
    required int huespedId,
    required DateTime fecha,
    required String hora,
    required int personas,
    required double monto,
    String? notas,
  }) async {
    try {
      final accessToken = await _storage.getAccessToken();
      final decoded = JwtDecoder.decode(accessToken!);
      final usuarioId = decoded[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
      ] as String?;

      final horaFormatted = hora.split(':').length == 2 ? '$hora:00' : hora;

      final data = {
        'usuarioId': usuarioId,
        'actividadId': actividadId,
        'fechaReserva': fecha.toIso8601String(),
        'horaReserva': horaFormatted,
        'numeroPersonas': personas,
        'montoTotal': monto,
        'notasEspeciales': notas,
      };

      final response = await _dio.post('/ReservasActividades/me', data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {
        return ReservaActividadApi.fromJson(response.data);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[ActividadesService] Create Error: ${e.message}');
      return null;
    }
  }

  
  Future<bool> cancelarReservaActividad(int reservaActividadId) async {
    try {
      debugPrint('[ActividadesService] Cancelando reserva: $reservaActividadId');
      
      final response = await _dio.delete('/ReservasActividades/me/$reservaActividadId');
      
      final success = response.statusCode == 200 || response.statusCode == 204;
      debugPrint('[ActividadesService] Cancelación exitosa: $success');
      
      return success;
    } on DioException catch (e) {
      debugPrint('[ActividadesService] Delete Error: ${e.message}');
      debugPrint('[ActividadesService] Response: ${e.response?.data}');
      return false;
    }
  }
}