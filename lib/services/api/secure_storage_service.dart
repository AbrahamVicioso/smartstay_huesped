

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../../models/auth/access_token_response.dart';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage();

  static const _keyToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyTokenType = 'token_type';
  static const _keyUserEmail = 'user_email';
  static const _keyUserId = 'user_id';

  

  
  Future<void> saveTokens(AccessTokenResponse response) async {
    await saveAccessToken(response.accessToken);
    await saveTokenType(response.tokenType ?? 'Bearer');
    if (response.refreshToken != null) {
      await _storage.write(key: _keyRefreshToken, value: response.refreshToken);
    }
  }

  
  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _keyToken, value: token);
  }

  Future<void> saveTokenType(String type) async {
    await _storage.write(key: _keyTokenType, value: type);
  }
  

  Future<void> saveUserEmail(String email) async => await _storage.write(key: _keyUserEmail, value: email);
  Future<void> saveUserId(String id) async => await _storage.write(key: _keyUserId, value: id);

  
  Future<String?> getAccessToken() async => await _storage.read(key: _keyToken);
  Future<String?> getRefreshToken() async => await _storage.read(key: _keyRefreshToken);
  Future<String?> getTokenType() async => await _storage.read(key: _keyTokenType);
  
  Future<bool> isTokenExpired() async {
    final token = await getAccessToken();
    if (token == null) return true;
    return JwtDecoder.isExpired(token);
  }

  
  Future<void> clearAll() async => await _storage.deleteAll();
  Future<void> deleteAll() async => await _storage.deleteAll();
}