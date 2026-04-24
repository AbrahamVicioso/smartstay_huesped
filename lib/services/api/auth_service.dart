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
        baseUrl: ApiConfig.authBaseUrl, 
        connectTimeout: const Duration(seconds: 15),
        receiveTimeout: const Duration(seconds: 15),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
      ),
    );
  }

  
  
  Future<bool> login(String email, String password) async {
    try {
      final response = await _dio.post('/Login', data: {
        'email': email,
        'password': password,
      });

      if (response.statusCode == 200) {
        
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

  
  
  Future<bool> register(String email, String password) async {
    try {
      final response = await _dio.post('/Register', data: {
        'email': email,
        'password': password,
      });

      
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AuthService] Register Error: $e');
      return false;
    }
  }

  
  
  Future<Map<String, dynamic>?> getInfo() async {
    try {
      final token = await _storage.getAccessToken();
      final type = await _storage.getTokenType() ?? 'Bearer';

      final response = await _dio.get(
        '/Info',
        options: Options(headers: {'Authorization': '$type $token'}),
      );

      if (response.statusCode == 200) {
        return response.data; 
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  
  
  Future<bool> forgotPassword(String email) async {
    try {
      final response = await _dio.post('/ForgotPassword', data: {'email': email});
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  
  Future<void> logout() async {
    await _storage.deleteAll();
  }

  
  
  Future<bool> asignarRol(String userId, String rol, {required String token}) async {
    try {
      final response = await _dio.post(
        '/Users/$userId/roles',
        data: {'userId': userId, 'roleName': rol},
        options: Options(headers: {'Authorization': 'Bearer $token'}),
      );
      return response.statusCode == 200;
    } catch (e) {
      debugPrint('[AuthService] Error al asignar rol: $e');
      return false;
    }
  }

  /// Create huesped profile for current authenticated user via Usuarios API
  Future<bool> crearHuespedMe(Map<String, dynamic> datos, {required String token}) async {
    try {
      final dioUsuarios = Dio(
        BaseOptions(
          baseUrl: ApiConfig.usuariosBaseUrl,
          connectTimeout: const Duration(seconds: 15),
          receiveTimeout: const Duration(seconds: 15),
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            'Authorization': 'Bearer $token',
          },
        ),
      );
      final response = await dioUsuarios.post('/Huesped/me', data: datos);
      return response.statusCode == 200 || response.statusCode == 201;
    } catch (e) {
      debugPrint('[AuthService] Error al crear huesped/me: $e');
      return false;
    }
  }
}