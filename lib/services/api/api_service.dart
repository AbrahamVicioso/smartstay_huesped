import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../models/auth/access_token_response.dart';
import '../../models/auth/login_request.dart';
import '../../models/auth/register_request.dart';
import '../../models/auth/forgot_password_request.dart';
import '../../models/auth/reset_password_request.dart';
import '../../models/auth/auth_exception.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';

/// Thrown when login requires a 2FA code to complete
class TwoFactorRequiredException implements Exception {
  const TwoFactorRequiredException();
}

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
        baseUrl: ApiConfig.authBaseUrl,
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
         
          if (_isAuthEndpoint(options.path)) {
            debugPrint('[v0] Skipping auth for: ${options.path}');
            return handler.next(options);
          }

          final accessToken = await _storage.getAccessToken();
          debugPrint('[v0] Token from storage: $accessToken');

          if (accessToken != null) {
            final tokenType = await _storage.getTokenType() ?? 'Bearer';
            options.headers['Authorization'] = '$tokenType $accessToken';
            debugPrint(
              '[v0] Authorization header set: $tokenType $accessToken',
            );
          } else {
            debugPrint('[v0] WARNING: No token found in storage!');
          }

          debugPrint('[v0] Final headers: ${options.headers}');
          return handler.next(options);
        },
        onError: (error, handler) async {
        
          if (error.response?.statusCode == 401) {
            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                
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
    return path.contains('/Login') ||
        path.contains('/Register') ||
        path.contains('/RefreshToken') ||
        path.contains('/ForgotPassword') ||
        path.contains('/ResetPassword');
  }

  Future<bool> _refreshToken() async {
    try {
      final refreshToken = await _storage.getRefreshToken();
      if (refreshToken == null) return false;

      final response = await _dio.post(
        '/RefreshToken',
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


  Future<void> register(RegisterRequest request) async {
    try {
      final response = await _dio.post('/Register', data: request.toJson());

      if (response.statusCode != 200) {
        throw AuthException(
          message: 'Error en el registro',
          statusCode: response.statusCode,
        );
      }
      
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<AccessTokenResponse> login(LoginRequest request) async {
    try {
      final response = await _dio.post('/Login', data: request.toJson());

      if (response.statusCode == 200) {
        final tokenResponse = AccessTokenResponse.fromJson(response.data);
        await _storage.saveTokens(tokenResponse);

        final savedToken = await _storage.getAccessToken();
        debugPrint('[v0] Token saved and retrieved: $savedToken');

        return tokenResponse;
      }

      throw AuthException(
        message: 'Error al iniciar sesión',
        statusCode: response.statusCode,
      );
    } on DioException catch (e) {
      // Detect 2FA required from backend
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map) {
          final detail = (data['detail'] as String? ?? '').toLowerCase();
          if (detail.contains('twofactor') || detail.contains('requirestwofactor')) {
            throw TwoFactorRequiredException();
          }
        }
      }
      throw _handleDioError(e);
    }
  }

  /// Send 2FA code to user's email
  Future<void> sendTwoFactorCode(String email) async {
    try {
      await _dio.post('/LoginSendTwoFactorCode', data: {'email': email});
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Verify 2FA code and get token
  Future<AccessTokenResponse> verifyTwoFactor(String email, String code) async {
    try {
      final response = await _dio.post(
        '/LoginVerifyTwoFactor',
        data: {'email': email, 'code': code},
      );
      if (response.statusCode == 200) {
        final tokenResponse = AccessTokenResponse.fromJson(response.data);
        await _storage.saveTokens(tokenResponse);
        return tokenResponse;
      }
      throw AuthException(message: 'Código 2FA inválido', statusCode: response.statusCode);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Get 2FA status for authenticated user
  Future<bool> getTwoFactorStatus() async {
    try {
      final response = await _dio.get('/TwoFactorStatus');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is Map) return data['isEnabled'] as bool? ?? false;
        if (data is bool) return data;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Initiate 2FA enable (backend sends/generates code)
  Future<bool> enableTwoFactor() async {
    try {
      final response = await _dio.post('/TwoFactorEnable');
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Confirm 2FA enable with received code
  Future<bool> confirmTwoFactor(String code) async {
    try {
      final response = await _dio.post('/TwoFactorConfirm', data: {'code': code});
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// Disable 2FA with password
  Future<bool> disableTwoFactor(String password) async {
    try {
      final response = await _dio.post('/TwoFactorDisable', data: {'password': password});
      return response.statusCode == 200;
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Future<void> forgotPassword(ForgotPasswordRequest request) async {
    try {
      final response = await _dio.post(
        '/ForgotPassword',
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
        '/ResetPassword',
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



  AuthException _handleDioError(DioException error) {
    if (error.response != null) {
      final data = error.response!.data;

   
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

 
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout) {
      return AuthException(
        message: 'Tiempo de espera agotado. Verifica tu conexión a internet.',
      );
    }

    if (error.type == DioExceptionType.connectionError) {
      return AuthException(
        message:
            'No se pudo conectar al servidor. Verifica tu conexión a internet.',
      );
    }

    return AuthException(message: error.message ?? 'Error desconocido');
  }
}
