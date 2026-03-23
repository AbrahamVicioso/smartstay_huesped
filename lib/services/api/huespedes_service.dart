import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/huesped.dart';
import '../secure_storage_service.dart';

class HuespedesService {
  late final Dio _dio;
  final SecureStorageService _storage = SecureStorageService();

  HuespedesService() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.usuariosBaseUrl, 
        connectTimeout: const Duration(seconds: 60),
        receiveTimeout: const Duration(seconds: 60),
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

  /// Obtiene el HuespedId llamando a GET /Huesped/user/{usuarioId}
  Future<int?> getHuespedIdByUsuarioId(String usuarioId) async {
    try {
      debugPrint('[HuespedesService] Buscando huesped para userId: $usuarioId');
      final response = await _dio.get('/Huesped/user/$usuarioId');

      if (response.statusCode == 200 && response.data != null) {
        final data = response.data as Map<String, dynamic>;
        final huespedId = data['huespedId'] as int;
        debugPrint('[HuespedesService] HuespedId encontrado: $huespedId');
        return huespedId;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error: ${e.message}');
      if (e.response?.statusCode == 500 || e.response?.statusCode == 404) {
        debugPrint('[HuespedesService] Usuario no tiene perfil de huesped');
        return null;
      }
      return null;
    }
  }

  /// Obtiene los datos completos del huesped por usuarioId
  /// GET /Huesped/user/{usuarioId}
  Future<Huesped?> getHuespedByUsuarioId(String usuarioId) async {
    try {
      debugPrint(
        '[HuespedesService] Obteniendo huesped para userId: $usuarioId',
      );
      final response = await _dio.get('/Huesped/user/$usuarioId');

      if (response.statusCode == 200 && response.data != null) {
        final huesped = Huesped.fromJson(response.data as Map<String, dynamic>);
        debugPrint(
          '[HuespedesService] Huesped encontrado: ${huesped.nombreCompleto}',
        );
        return huesped;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error obteniendo huesped: ${e.message}');
      if (e.response?.statusCode == 500 || e.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  /// Crea un nuevo huesped
  /// POST /Huesped
  Future<Huesped?> createHuesped(Huesped huesped) async {
    try {
      debugPrint(
        '[HuespedesService] Creando huesped para userId: ${huesped.usuarioId}',
      );
      final response = await _dio.post(
        '/Huesped',
        data: huesped.toJsonForCreate(),
      );

      debugPrint('[HuespedesService] Create status: ${response.statusCode}');
      debugPrint('[HuespedesService] Create data: ${response.data}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          return Huesped.fromJson(response.data as Map<String, dynamic>);
        }
        // If the API doesn't return the created object, fetch it
        return await getHuespedByUsuarioId(huesped.usuarioId);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error creando huesped: ${e.message}');
      debugPrint('[HuespedesService] Response: ${e.response?.data}');
      return null;
    }
  }

  /// Actualiza un huesped existente
  /// PUT /Huesped/{id}
  Future<Huesped?> updateHuesped(int huespedId, Huesped huesped) async {
    try {
      debugPrint('[HuespedesService] Actualizando huesped ID: $huespedId');
      final response = await _dio.put(
        '/Huesped/$huespedId',
        data: huesped.toJsonForUpdate(),
      );

      debugPrint('[HuespedesService] Update status: ${response.statusCode}');

      if (response.statusCode == 200) {
        if (response.data != null && response.data is Map<String, dynamic>) {
          return Huesped.fromJson(response.data as Map<String, dynamic>);
        }
        // Refetch after update
        return await getHuespedByUsuarioId(huesped.usuarioId);
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error actualizando huesped: ${e.message}');
      debugPrint('[HuespedesService] Response: ${e.response?.data}');
      return null;
    }
  }

  /// Busca un huésped por número de documento
  /// GET /Huesped/documento/{numeroDocumento}
  Future<Huesped?> getHuespedByDocumento(String numeroDocumento) async {
    try {
      debugPrint('[HuespedesService] Buscando huesped por documento: $numeroDocumento');
      final response = await _dio.get('/Huesped/documento/$numeroDocumento');

      if (response.statusCode == 200 && response.data != null) {
        final huesped = Huesped.fromJson(response.data as Map<String, dynamic>);
        debugPrint('[HuespedesService] Huesped encontrado con documento: ${huesped.nombreCompleto}');
        return huesped;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error buscando huesped por documento: ${e.message}');
      if (e.response?.statusCode == 404) {
        // No se encontró ningún huésped con ese documento
        return null;
      }
      return null;
    }
  }

  /// Obtiene un huésped por ID
  /// GET /Huesped/{id}
  Future<Huesped?> getHuespedById(int huespedId) async {
    try {
      debugPrint('[HuespedesService] Buscando huesped por ID: $huespedId');
      final response = await _dio.get('/Huesped/$huespedId');

      if (response.statusCode == 200 && response.data != null) {
        final huesped = Huesped.fromJson(response.data as Map<String, dynamic>);
        debugPrint('[HuespedesService] Huesped encontrado: ${huesped.nombreCompleto}');
        return huesped;
      }
      return null;
    } on DioException catch (e) {
      debugPrint('[HuespedesService] Error buscando huesped por ID: ${e.message}');
      if (e.response?.statusCode == 404) {
        return null;
      }
      return null;
    }
  }

  /// Verifica si ya existe un huésped con el número de documento
  Future<bool> documentoExiste(String numeroDocumento) async {
    final huesped = await getHuespedByDocumento(numeroDocumento);
    return huesped != null;
  }
}
