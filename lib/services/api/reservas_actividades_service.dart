import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/reserva_actividad.dart';
import '../../config/api_config.dart';
import '../secure_storage_service.dart';

class ReservasActividadesService {
  static final ReservasActividadesService _instance =
      ReservasActividadesService._internal();
  factory ReservasActividadesService() => _instance;
  ReservasActividadesService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: '${ApiConfig.reservasBaseUrl}/api',
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

  // GET /api/ReservasActividades
  Future<List<ReservaActividadApi>> getAll() async {
    try {
      final response = await _dio.get('/ReservasActividades');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => ReservaActividadApi.fromJson(json)).toList();
      }

      throw Exception('Error al obtener reservas de actividades');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // GET /api/ReservasActividades/{id}
  Future<ReservaActividadApi> getById(int id) async {
    try {
      final response = await _dio.get('/ReservasActividades/$id');

      if (response.statusCode == 200) {
        return ReservaActividadApi.fromJson(response.data);
      }

      throw Exception('Error al obtener reserva de actividad');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // POST /api/ReservasActividades
  Future<ReservaActividadApi> create(
      CreateReservaActividadCommand command) async {
    try {
      final response = await _dio.post(
        '/ReservasActividades',
        data: command.toJson(),
      );

      if (response.statusCode == 200) {
        return ReservaActividadApi.fromJson(response.data);
      }

      throw Exception('Error al crear reserva de actividad');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // PUT /api/ReservasActividades/{id}
  Future<ReservaActividadApi> update(
      int id, UpdateReservaActividadCommand command) async {
    try {
      final response = await _dio.put(
        '/ReservasActividades/$id',
        data: command.toJson(),
      );

      if (response.statusCode == 200) {
        return ReservaActividadApi.fromJson(response.data);
      }

      throw Exception('Error al actualizar reserva de actividad');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  // DELETE /api/ReservasActividades/{id}
  Future<void> delete(int id) async {
    try {
      final response = await _dio.delete('/ReservasActividades/$id');

      if (response.statusCode != 200) {
        throw Exception('Error al eliminar reserva de actividad');
      }
    } on DioException catch (e) {
      throw _handleError(e);
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
