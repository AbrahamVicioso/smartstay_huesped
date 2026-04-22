import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/actividad_recreativa.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';

class ActividadesRecreativasService {
  static final ActividadesRecreativasService _instance =
      ActividadesRecreativasService._internal();
  factory ActividadesRecreativasService() => _instance;
  ActividadesRecreativasService._internal() {
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

  Future<List<ActividadRecreativa>> getAll() async {
    try {
      final response = await _dio.get('/ActividadesRecreativas');

      if (response.statusCode == 200) {
        final List<dynamic> data = response.data is List 
            ? response.data 
            : (response.data['\$values'] ?? []);
        return data.map((json) => ActividadRecreativa.fromJson(json)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<ActividadRecreativa> getById(int id) async {
    try {
      final response = await _dio.get('/ActividadesRecreativas/$id');
      if (response.statusCode == 200) {
        return ActividadRecreativa.fromJson(response.data);
      }
      throw Exception('Error_Fetch_Actividad');
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Exception _handleError(DioException error) {
    final message = error.response?.data?['title'] ?? 'Error_Conexion';
    return Exception(message);
  }
}