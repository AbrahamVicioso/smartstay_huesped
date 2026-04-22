import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import '../../config/api_config.dart';
import 'secure_storage_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal() {
    _initializeDio();
  }

  late Dio _dio;
  final _storage = SecureStorageService();

  void _initializeDio() {
    _dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.authBaseUrl, // La URL base que apunta a este controlador
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// 1. LOGIN
  /// Corresponde al [HttpPost] Login en C#
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/Login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        // El AccessTokenResponse de C# suele traer accessToken y expiresIn
        final String token = response.data['accessToken'];
        final String type = response.data['tokenType'] ?? 'Bearer';
        
        await _storage.saveAccessToken(token);
        await _storage.saveTokenType(type);
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('[AuthService] Login Error: $e');
      return false;
    }
  }

  /// 2. REGISTER
  /// Corresponde al [HttpPost] Register en C#
  Future<bool> register(String email, String password) async {
    try {
      final response = await _dio.post('/Register', data: {
        'email': email,
        'password': password,
      });

      // El handler de C# devuelve TypedResults.Ok (200)
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AuthService] Register Error: $e');
      return false;
    }
  }

  /// 3. INFO (Obtener datos del usuario logueado)
  /// Corresponde al [HttpGet] Info con [Authorize]
  Future<Map<String, dynamic>?> getInfo() async {
    try {
      final token = await _storage.getAccessToken();
      final type = await _storage.getTokenType() ?? 'Bearer';

      final response = await _dio.get(
        '/Info',
        options: Options(headers: {'Authorization': '$type $token'}),
      );

      if (response.statusCode == 200) {
        return response.data; // Retorna email e IsEmailConfirmed
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// 4. FORGOT PASSWORD
  /// Corresponde al [HttpPost] ForgotPassword
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/ForgotPassword', data: {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// 5. LOGOUT 
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  /// 6. ASIGNAR ROL
  
  Future<bool> asignarRol(String userId, String rol, {required String token}) async {
    try {
      final response = await _dio.post(
        '/AssignRole', // Ajusta según tu endpoint real en ASP.NET
        data: {'userId': userId, 'roleName': rol},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AuthService] Error al asignar rol: $e');
      return false;
    }
  }

  /// 7. CREAR HUÉSPED (Sincronización con tabla Huespedes)
  Future<bool> crearHuesped(Map<String, dynamic> datos, {required String token}) async {
    try {
   
      final response = await _dio.post(
        '/Huespedes', 
        data: datos,
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[AuthService] Error al crear huésped: $e');
      return false;
    }
  }
}