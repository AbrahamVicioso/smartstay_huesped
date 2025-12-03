import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../models/auth/access_token_response.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/forgot_password_request.dart';
import '../models/auth/reset_password_request.dart';
import '../models/auth/auth_exception.dart';
import '../config/api_config.dart';
import 'secure_storage_service.dart';

class ApiService {
  static final ApiService _instance = ApiService._internal();
  factory ApiService() => _instance;
  ApiService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

  Dio get dio => _dio;

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
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
          // No agregar token para endpoints de autenticación
          if (_isAuthEndpoint(options.path)) {
            return handler.next(options);
          }

          // Agregar token a las demás peticiones
          final accessToken = await _storage.getAccessToken();
          if (accessToken != null) {
            final tokenType = await _storage.getTokenType() ?? 'Bearer';
            options.headers['Authorization'] = '$tokenType $accessToken';
          }

          return handler.next(options);
        },
        onError: (error, handler) async {
          // Si recibimos 401, intentar refrescar el token
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                // Reintentar la petición original
                final options = error.requestOptions;
                final accessToken = await _storage.getAccessToken();
                final tokenType = await _storage.getTokenType() ?? 'Bearer';
                options.headers['Authorization'] = '$tokenType $accessToken';

                final response = await _dio.fetch(options);
                return handler.resolve(response);
              }
            } catch (e) {
              debugPrint('Error refreshing token: $e');
            }
          }

          return handler.next(error);
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

  bool _isAuthEndpoint(String path) {
    return path.contains('/login') ||
        path.contains('/register') ||
        path.contains('/refresh') ||
        path.contains('/forgotPassword') ||
        path.contains('/resetPassword');
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/refresh',
        data: {'refreshToken': refreshToken},
      );

      if (response.statusCode == 200) {
        final tokenResponse = AccessTokenResponse.fromJson(response.data);
        await _storage.saveTokens(tokenResponse);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Error in _refreshToken: $e');
      return false;
    }
  }

  // AUTH ENDPOINTS

  Future<void> register(RegisterRequest request) async {
    try {
      final response = await _dio.post(
        '/register',
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthException(
          message: 'Error en el registro',
          statusCode: response.statusCode,
        );
      }
      // Registro exitoso, no retorna tokens
      // El usuario debe hacer login después
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AccessTokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post(
        '/login',
        data: request.toJson(),
      );

      if (response.statusCode == 200) {
        final tokenResponse = AccessTokenResponse.fromJson(response.data);
        await _storage.saveTokens(tokenResponse);
        return tokenResponse;
      }

      throw AuthException(
        message: 'Error al iniciar sesión',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/forgotPassword',
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthException(
          message: 'Error al solicitar recuperación de contraseña',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> resetPassword(ResetPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/resetPassword',
        data: request.toJson(),
      );

      if (response.statusCode != 200) {
        throw AuthException(
          message: 'Error al resetear contraseña',
          statusCode: response.statusCode,
        );
      }
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<Map<String, dynamic>> getUserInfo() async {
    try {
      final response = await _dio.get('/manage/info');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      throw AuthException(
        message: 'Error al obtener información del usuario',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  // ERROR HANDLING

  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;

      // Manejar errores de validación
      if (data is Map<String, dynamic>) {
        final errors = data['errors'] as Map<String, dynamic>?;
        final detail = data['detail'] as String?;
        final title = data['title'] as String?;

        return AuthException(
          message: title ?? detail ?? 'Error en la solicitud',
          statusCode: error.response!.statusCode,
          errors: errors,
        );
      }

      return AuthException(
        message: 'Error en la solicitud',
        statusCode: error.response!.statusCode,
      );
    }

    // Errores de red
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AuthException(
        message: 'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    }

    return AuthException(
      message: error.message ?? 'Error desconocido',
    );
  }
}
