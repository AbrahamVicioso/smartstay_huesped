import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/habitacion.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';

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

  Future<Habitacion?> getById(int id) async {
    try {
      final response = await _dio.get('/Habitacion/$id');
      if (response.statusCode == 200 && response.data != null) {
        return Habitacion.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HabitacionService] Error fetching room $id: ${e.message}');
      return null;
    }
  }

  Future<List<Habitacion>> getByHotelId(int hotelId) async {
    try {
      final response = await _dio.get('/Habitacion/hotel/$hotelId');
      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['\$values'] ?? []);
        return data.map((json) => Habitacion.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      debugPrint('[HabitacionService] Error fetching rooms for hotel $hotelId');
      return [];
    }
  }

  Future<List<Habitacion>> getByIds(List<int> habitacionIds) async {
    if (habitacionIds.isEmpty) return [];
    
    try {
      // Optimizamos usando Future.wait para peticiones en paralelo
      final futures = habitacionIds.map((id) => getById(id));
      final results = await Future.wait(futures);
      
      return results.whereType<Habitacion>().toList();
    } catch (e) {
      debugPrint('[HabitacionService] Batch fetch error: $e');
      return [];
    }
  }

  Exception _handleError(DioException error) {
    final message = error.response?.data?['title'] ?? 'Error_Habitacion_Service';
    return Exception(message);
  }
}