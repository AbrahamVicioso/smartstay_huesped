import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/reserva_api.dart';
import '../../models/api/reserva_actividad.dart';
import '../../config/api_config.dart';
import '../secure_storage_service.dart';

class ReservasService {
  static final ReservasService _instance = ReservasService._internal();
  factory ReservasService() => _instance;
  ReservasService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.reservasBaseUrl, // http://localhost:5141
        connectTimeout: ApiConfig.connectionTimeout,
        receiveTimeout: ApiConfig.receiveTimeout,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );

    // Interceptor para agregar el token automáticamente
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

    // Interceptor para logging en modo debug
    if (kDebugMode) {
      _dio.interceptors.add(
        LogInterceptor(
          requestBody: true,
          responseBody: true,
          error: true,
          requestHeader: true,
          responseHeader: false,
        ),
      );
    }
  }

  Future<List<ReservaApi>> getMisReservas() async {
    try {
      final response = await _dio.get('/me');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }
      throw Exception('Error al obtener mis reservas');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/Reservas
  Future<List<ReservaApi>> getAll() async {
    try {
      final response = await _dio.get('/');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }

      throw Exception('Error al obtener reservas');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<ReservaActividadApi>> getReservasActividadesByHuespedId(
    int huespedId,
  ) async {
    try {
      debugPrint(
        '[ReservasService] Obteniendo reservas actividades para huespedId: $huespedId',
      );
      debugPrint(
        '[ReservasService] URL: ${_dio.options.baseUrl}/ReservasActividades',
      );

      final response = await _dio.get('/ReservasActividades');

      debugPrint('[ReservasService] Status: ${response.statusCode}');
      debugPrint(
        '[ReservasService] Response type: ${response.data.runtimeType}',
      );

      if (response.statusCode == 200 && response.data != null) {
        List<dynamic> allReservas;

        if (response.data is List) {
          allReservas = response.data as List<dynamic>;
        } else if (response.data is Map) {
          final map = response.data as Map<String, dynamic>;
          allReservas = map['\$values'] ?? map['data'] ?? map['items'] ?? [];
        } else {
          return [];
        }

        debugPrint(
          '[ReservasService] Total reservas actividades: ${allReservas.length}',
        );

        // Filtrar por huespedId
        final misReservas = allReservas
            .where((r) => r['huespedId'] == huespedId)
            .map(
              (json) =>
                  ReservaActividadApi.fromJson(json as Map<String, dynamic>),
            )
            .toList();

        debugPrint(
          '[ReservasService] Reservas actividades del huesped $huespedId: ${misReservas.length}',
        );

        return misReservas;
      }

      return [];
    } on DioException catch (e) {
      debugPrint('[ReservasService] Error: ${e.message}');
      debugPrint('[ReservasService] Response: ${e.response?.data}');
      return [];
    }
  }

  // GET /api/Reservas/{id}
  Future<ReservaApi> getById(int id) async {
    try {
      final response = await _dio.get('/$id');

      if (response.statusCode == 200) {
        return ReservaApi.fromJson(response.data);
      }

      throw Exception('Error al obtener reserva');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/Reservas/huesped/{huespedId}
  Future<List<ReservaApi>> getByHuespedId(int huespedId) async {
    try {
      final response = await _dio.get('/huesped/$huespedId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReservaApi.fromJson(json)).toList();
      }

      throw Exception('Error al obtener reservas del huésped');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<List<dynamic>> getReservasActividades() async {
    try {
      final response = await _dio.get('/ReservasActividades');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      throw Exception('Error al obtener reservas de actividades');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  /// Crea una nueva reserva de actividad
  /// POST /ReservasActividades
  Future<ReservaActividadApi?> crearReservaActividad({
    required int actividadId,
    required int huespedId,
    required DateTime fechaReserva,
    required String horaReserva,
    required int numeroPersonas,
    required double montoTotal,
    String? notasEspeciales,
  }) async {
    try {
      debugPrint('[ReservasService] Creando reserva de actividad');
      debugPrint(
        '[ReservasService] URL: ${_dio.options.baseUrl}/ReservasActividades',
      );

      final data = {
        'actividadId': actividadId,
        'huespedId': huespedId,
        'fechaReserva': fechaReserva.toIso8601String(),
        'horaReserva': horaReserva,
        'numeroPersonas': numeroPersonas,
        'montoTotal': montoTotal,
        'notasEspeciales': notasEspeciales,
      };

      debugPrint('[ReservasService] Request data: $data');

      final response = await _dio.post('/ReservasActividades', data: data);

      debugPrint('[ReservasService] Create status: ${response.statusCode}');
      debugPrint('[ReservasService] Response: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          return ReservaActividadApi.fromJson(
            response.data as Map<String, dynamic>,
          );
        }
        return null;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[ReservasService] Error creando reserva: ${e.message}');
      debugPrint('[ReservasService] Response: ${e.response?.data}');
      return null;
    }
  }

  /// Cancela una reserva de actividad
  /// DELETE /ReservasActividades/{id}
  Future<bool> cancelarReservaActividad(int reservaActividadId) async {
    try {
      debugPrint(
        '[ReservasService] Cancelando reserva ID: $reservaActividadId',
      );
      debugPrint(
        '[ReservasService] URL: ${_dio.options.baseUrl}/ReservasActividades/$reservaActividadId',
      );

      final response = await _dio.delete(
        '/ReservasActividades/$reservaActividadId',
      );

      debugPrint('[ReservasService] Delete status: ${response.statusCode}');

      return response.statusCode == 200 || response.statusCode == 204;
    } on DioException catch (e) {
      debugPrint('[ReservasService] Error cancelando reserva: ${e.message}');
      debugPrint('[ReservasService] Response: ${e.response?.data}');
      return false;
    }
  }

  Exception _handleError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;

      if (data is Map<String, dynamic>) {
        final detail = data['detail'] as String?;
        final title = data['title'] as String?;
        return Exception(title ?? detail ?? 'Error en la solicitud');
      }

      return Exception('Error en la solicitud: ${error.response!.statusCode}');
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return Exception('Tiempo de espera agotado. Verifica tu conexión.');
    }

    if (error.type == DioExceptionType.connectionError) {
      return Exception('No se pudo conectar al servidor.');
    }

    return Exception(error.message ?? 'Error desconocido');
  }
}
