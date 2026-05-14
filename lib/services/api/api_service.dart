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

  bool _isRefreshing = false;
  int _refreshAttempts = 0;
  static const int _maxRefreshAttempts = 3;

  // Callback to notify app of forced logout (set by AuthProvider)
  static void Function()? onForceLogout;

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

          if (error.response?.statusCode == 401 &&
              !_isAuthEndpoint(error.requestOptions.path)) {
            if (_isRefreshing || _refreshAttempts >= _maxRefreshAttempts) {
              debugPrint('[v0] Max refresh attempts reached or already refreshing — forcing logout');
              _isRefreshing = false;
              _refreshAttempts = 0;
              await _storage.clearAll();
              onForceLogout?.call();
              return handler.next(error);
            }

            _isRefreshing = true;
            _refreshAttempts++;
            debugPrint('[v0] Refresh attempt $_refreshAttempts/$_maxRefreshAttempts');

            try {
              final refreshed = await _refreshToken();
              if (refreshed) {
                _refreshAttempts = 0;
                final options = error.requestOptions;
                final accessToken = await _storage.getAccessToken();
                final tokenType = await _storage.getTokenType() ?? 'Bearer';
                options.headers['Authorization'] = '$tokenType $accessToken';
                final response = await _dio.fetch(options);
                return handler.resolve(response);
              } else {
                debugPrint('[v0] Refresh failed — forcing logout');
                _refreshAttempts = 0;
                await _storage.clearAll();
                onForceLogout?.call();
              }
            } catch (e) {
              debugPrint('Error refreshing token: $e');
              _refreshAttempts = 0;
              await _storage.clearAll();
              onForceLogout?.call();
            } finally {
              _isRefreshing = false;
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
        final data = response.data as Map<String, dynamic>;

        if (data['requiresTwoFactor'] == true) {
          throw const TwoFactorRequiredException();
        }

        final tokenResponse = AccessTokenResponse.fromJson(data);
        await _storage.saveTokens(tokenResponse);

        final savedToken = await _storage.getAccessToken();
        debugPrint('[v0] Token saved and retrieved: $savedToken');

        return tokenResponse;
      }

      throw AuthException(
        message: 'Error al iniciar sesión',
        statusCode: response.statusCode,
      );
    } on TwoFactorRequiredException {
      rethrow;
    } on DioException catch (e) {
      if (e.response?.statusCode == 401) {
        final data = e.response?.data;
        if (data is Map) {
          final detail = (data['detail'] as String? ?? '').toLowerCase();
          if (detail.contains('twofactor') || detail.contains('requirestwofactor')) {
            throw const TwoFactorRequiredException();
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
      debugPrint('[2FA] TwoFactorStatus response: ${response.data}');
      if (response.statusCode == 200) {
        final data = response.data;
        if (data is bool) return data;
        if (data is Map) {
          return data['isEnabled'] as bool? ??
              data['enabled'] as bool? ??
              data['twoFactorEnabled'] as bool? ??
              data['isTwoFactorEnabled'] as bool? ??
              false;
        }
      }
      return false;
    } catch (e) {
      debugPrint('[2FA] getTwoFactorStatus error: $e');
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

        if (detail != null && detail.isNotEmpty) {
          return AuthException(
            message: detail,
            statusCode: error.response!.statusCode,
            errors: errors,
          );
        }

        return AuthException(
          message: title ?? 'Error en la solicitud',
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
