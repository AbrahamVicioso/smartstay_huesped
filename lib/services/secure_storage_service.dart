import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../models/auth/access_token_response.dart';
import 'dart:convert';

class SecureStorageService {
  static final SecureStorageService _instance = SecureStorageService._internal();
  factory SecureStorageService() => _instance;
  SecureStorageService._internal();

  final _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _tokenTypeKey = 'token_type';
  static const String _expiresInKey = 'expires_in';
  static const String _tokenTimestampKey = 'token_timestamp';
  static const String _userIdKey = 'user_id';
  static const String _userEmailKey = 'user_email';

  // Token Management
  Future<void> saveTokens(AccessTokenResponse tokenResponse) async {
    await _storage.write(key: _accessTokenKey, value: tokenResponse.accessToken);
    await _storage.write(key: _refreshTokenKey, value: tokenResponse.refreshToken);
    await _storage.write(key: _tokenTypeKey, value: tokenResponse.tokenType);
    await _storage.write(key: _expiresInKey, value: tokenResponse.expiresIn.toString());
    await _storage.write(
      key: _tokenTimestampKey,
      value: DateTime.now().millisecondsSinceEpoch.toString(),
    );
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<String?> getTokenType() async {
    return await _storage.read(key: _tokenTypeKey);
  }

  Future<bool> isTokenExpired() async {
    final timestampStr = await _storage.read(key: _tokenTimestampKey);
    final expiresInStr = await _storage.read(key: _expiresInKey);

    if (timestampStr == null || expiresInStr == null) {
      return true;
    }

    final timestamp = int.tryParse(timestampStr);
    final expiresIn = int.tryParse(expiresInStr);

    if (timestamp == null || expiresIn == null) {
      return true;
    }

    final tokenDate = DateTime.fromMillisecondsSinceEpoch(timestamp);
    final expirationDate = tokenDate.add(Duration(seconds: expiresIn));

    // Consider token expired 5 minutes before actual expiration
    final bufferTime = expirationDate.subtract(const Duration(minutes: 5));

    return DateTime.now().isAfter(bufferTime);
  }

  Future<AccessTokenResponse?> getStoredTokens() async {
    final accessToken = await getAccessToken();
    final refreshToken = await getRefreshToken();
    final tokenType = await getTokenType();
    final expiresInStr = await _storage.read(key: _expiresInKey);

    if (accessToken == null || refreshToken == null) {
      return null;
    }

    return AccessTokenResponse(
      accessToken: accessToken,
      refreshToken: refreshToken,
      tokenType: tokenType ?? 'Bearer',
      expiresIn: int.tryParse(expiresInStr ?? '3600') ?? 3600,
    );
  }

  // User Data
  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> saveUserEmail(String email) async {
    await _storage.write(key: _userEmailKey, value: email);
  }

  Future<String?> getUserEmail() async {
    return await _storage.read(key: _userEmailKey);
  }

  // Clear all data
  Future<void> clearAll() async {
    await _storage.deleteAll();
  }

  // Clear only tokens
  Future<void> clearTokens() async {
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _tokenTypeKey);
    await _storage.delete(key: _expiresInKey);
    await _storage.delete(key: _tokenTimestampKey);
  }
}
