import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../secure_storage_service.dart';

class HuespedesService {
  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  HuespedesService() {
    // SIN /api porque la ruta es /Huesped/user/{id} directamente
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.usuariosBaseUrl,
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
          final tokenType = await _storage.getTokenType() ?? 'Bearer';
          if (accessToken != null) {
            options.headers['Authorization'] = '$tokenType $accessToken';
          }
          return handler.next(options);
        },
      ),
    );
  }

  /// Obtiene el HuespedId llamando a GET /Huesped/user/{usuarioId}
  Future<int?> getHuespedIdByUsuarioId(String usuarioId) async {
    try {
      debugPrint('[HuespedesService] Buscando huesped para userId: $usuarioId');
      debugPrint(
        '[HuespedesService] URL: ${_dio.options.baseUrl}/Huesped/user/$usuarioId',
      );

      final response = await _dio.get('/Huesped/user/$usuarioId');

      debugPrint('[HuespedesService] Status: ${response.statusCode}');
      debugPrint('[HuespedesService] Data: ${response.data}');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final huespedId = data['huespedId'] as int;
        debugPrint('[HuespedesService] HuespedId encontrado: $huespedId');
        return huespedId;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error: ${e.message}');
      debugPrint('[HuespedesService] Response: ${e.response?.data}');
      // Si es 404/500 significa que no tiene huesped asociado
      if (e.response?.statusCode == 500 || e.response?.statusCode == 404) {
        debugPrint('[HuespedesService] Usuario no tiene perfil de huesped');
        return null;
      }
      return null;
    }
  }
}
