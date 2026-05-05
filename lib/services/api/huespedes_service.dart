import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import '../../models/huesped.dart';
import 'secure_storage_service.dart';

class HuespedesService {
  static final HuespedesService _instance = HuespedesService._internal();
  factory HuespedesService() => _instance;
  HuespedesService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.usuariosBaseUrl,
        connectTimeout: const Duration(seconds: 30),
        receiveTimeout: const Duration(seconds: 30),
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

  /// Get huesped for the authenticated user via JWT (preferred)
  Future<Huesped?> getHuespedMe() async {
    try {
      final response = await _dio.get('/Huesped/me');
      if (response.statusCode == 200 && response.data != null) {
        return Huesped.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[HuespedesService] getHuespedMe Error: $e');
      return null;
    }
  }

  Future<int?> getHuespedIdByUsuarioId(String usuarioId) async {
    try {
      final response = await _dio.get('/Huesped/user/$usuarioId');
      if (response.statusCode == 200 && response.data != null) {
        return response.data['huespedId'] as int;
      }
      return null;
    } catch (e) {
      debugPrint('[HuespedesService] getHuespedIdByUsuarioId Error: $e');
      return null;
    }
  }

  Future<Huesped?> getHuespedByUsuarioId(String usuarioId) async {
    try {
      final response = await _dio.get('/Huesped/user/$usuarioId');
      if (response.statusCode == 200 && response.data != null) {
        return Huesped.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      debugPrint('[HuespedesService] getHuespedByUsuarioId Error: $e');
      return null;
    }
  }

  Future<Huesped?> createHuesped(Huesped huesped) async {
    try {
      final response = await _dio.post(
        '/Huesped',
        data: huesped.toJsonForCreate(),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return response.data != null 
            ? Huesped.fromJson(response.data as Map<String, dynamic>)
            : await getHuespedByUsuarioId(huesped.usuarioId);
      }
      return null;
    } catch (e) {
      debugPrint('[HuespedesService] createHuesped Error: $e');
      return null;
    }
  }

 Future<Huesped?> updateHuesped(int huespedId, Huesped huesped) async {
  try {
    debugPrint('PUT /Huesped/$huespedId body: ${huesped.toJsonForUpdate()}');

    final response = await _dio.put(
      '/Huesped/$huespedId',
      data: huesped.toJsonForUpdate(),
    );

    debugPrint('PUT response: ${response.statusCode} ${response.data}');

    if (response.statusCode == 200) {
      return response.data != null
          ? Huesped.fromJson(response.data as Map<String, dynamic>)
          : await getHuespedByUsuarioId(huesped.usuarioId);
    }
    return null;
  } on DioException catch (e) {
    final data = e.response?.data;
    final msg = (data is Map ? data['message'] : null) as String?;
    debugPrint('[HuespedesService] updateHuesped Error: $e');
    throw Exception(msg ?? 'Error al actualizar el perfil (${e.response?.statusCode ?? 'sin respuesta'})');
  } catch (e) {
    debugPrint('[HuespedesService] updateHuesped Error: $e');
    rethrow;
  }
}
  Future<Huesped?> getHuespedByDocumento(String numeroDocumento) async {
    try {
      final response = await _dio.get('/Huesped/documento/$numeroDocumento');
      if (response.statusCode == 200 && response.data != null) {
        return Huesped.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Huesped?> getHuespedById(int huespedId) async {
    try {
      final response = await _dio.get('/Huesped/$huespedId');
      if (response.statusCode == 200 && response.data != null) {
        return Huesped.fromJson(response.data as Map<String, dynamic>);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  Future<Huesped?> createHuespedMe(Map<String, dynamic> datos) async {
    try {
      final response = await _dio.post('/Huesped/me', data: datos);
      if (response.statusCode == 200 || response.statusCode == 201) {
        if (response.data != null) {
          return Huesped.fromJson(response.data as Map<String, dynamic>);
        }
        return await getHuespedMe();
      }
      return null;
    } on DioException catch (e) {
      final data = e.response?.data;
      final msg = (data is Map ? data['message'] : null) as String?;
      debugPrint('[HuespedesService] createHuespedMe Error: $e');
      throw Exception(msg ?? 'Error al guardar el perfil (${e.response?.statusCode ?? 'sin respuesta'})');
    } catch (e) {
      debugPrint('[HuespedesService] createHuespedMe Error: $e');
      rethrow;
    }
  }

  Future<bool> documentoExiste(String numeroDocumento) async {
    final huesped = await getHuespedByDocumento(numeroDocumento);
    return huesped != null;
  }
}
