import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/api/credencial_acceso.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';

class CredencialesService {
  static final CredencialesService _instance = CredencialesService._internal();
  factory CredencialesService() => _instance;
  CredencialesService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.dispositivosBaseUrl,
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

  Future<List<CredencialAcceso>> getMisCredenciales() async {
    try {
      final response = await _dio.get('/credencialesacceso/me/huesped');
      if (response.statusCode == 200) {
        final data = response.data;
        List<dynamic> list;
        if (data is List) {
          list = data;
        } else if (data is Map) {
          list = (data['\$values'] ?? data['items'] ?? data['data'] ?? []) as List;
        } else {
          return [];
        }
        return list.map((j) => CredencialAcceso.fromJson(j as Map<String, dynamic>)).toList();
      }
      return [];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }

  Future<void> toggleCredencial(int credencialId) async {
    try {
      await _dio.post('/credencialesacceso/me/huesped/$credencialId/toggle');
    } on DioException catch (e) {
      final data = e.response?.data;
      String msg;
      if (data is String && data.isNotEmpty) {
        msg = data;
      } else if (data is Map) {
        msg = (data['message'] ?? data['title'] ?? '').toString();
      } else {
        msg = 'Error al cambiar estado de la credencial (${e.response?.statusCode})';
      }
      throw Exception(msg);
    }
  }

  Exception _handleError(DioException e) {
    final data = e.response?.data;
    final msg = (data is Map ? (data['message'] ?? data['title']) : null)?.toString()
        ?? 'Error de conexión';
    return Exception(msg);
  }
}
