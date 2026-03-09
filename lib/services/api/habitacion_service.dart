import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/habitacion.dart';
import '../../config/api_config.dart';
import '../secure_storage_service.dart';

class HabitacionService {
  static final HabitacionService _instance = HabitacionService._internal();
  factory HabitacionService() => _instance;
  HabitacionService._internal() {
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

  /// GET /api/Habitacion/{id}
  Future<Habitacion?> getById(int id) async {
    try {
      final response = await _dio.get('/Habitacion/$id');

      if (response.statusCode == 200 && response.data != null) {
        return Habitacion.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      _handleError(e);
      return null;
    }
  }

  /// GET /api/Habitacion
  Future<List<Habitacion>> getAll() async {
    try {
      final response = await _dio.get('/Habitacion');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Habitacion.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  /// GET /api/Habitacion/hotel/{hotelId}
  Future<List<Habitacion>> getByHotelId(int hotelId) async {
    try {
      final response = await _dio.get('/Habitacion/hotel/$hotelId');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data as List<dynamic>;
        return data.map((json) => Habitacion.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      _handleError(e);
      return [];
    }
  }

  /// Obtiene las habitaciones asociadas a una lista de IDs
  Future<List<Habitacion>> getByIds(List<int> habitacionIds) async {
    if (habitacionIds.isEmpty) return [];
    
    final List<Habitacion> habitaciones = [];
    
    for (final id in habitacionIds) {
      final habitacion = await getById(id);
      if (habitacion != null) {
        habitaciones.add(habitacion);
      }
    }
    
    return habitaciones;
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
