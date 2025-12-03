import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/reserva.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/forgot_password_request.dart';
import '../models/auth/reset_password_request.dart';
import '../models/auth/auth_exception.dart';
import 'api_service.dart';
import 'secure_storage_service.dart';

class AuthProvider with ChangeNotifier {
  User? _usuario;
  List<Reserva> _habitaciones = [];
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _apiService = ApiService();
  final _storage = SecureStorageService();

  User? get usuario => _usuario;
  List<Reserva> get habitaciones => _habitaciones;
  Reserva? get reservaActual => _habitaciones.isNotEmpty ? _habitaciones.first : null;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Inicializar y cargar datos guardados
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // Verificar si hay tokens guardados
      final accessToken = await _storage.getAccessToken();

      if (accessToken != null) {
        // Verificar si el token no ha expirado
        final isExpired = await _storage.isTokenExpired();

        if (!isExpired) {
          // Token válido, obtener información del usuario
          await _loadUserInfo();
          _isAuthenticated = true;
        } else {
          // Token expirado, intentar refrescar
          final refreshToken = await _storage.getRefreshToken();
          if (refreshToken != null) {
            try {
              await _apiService.dio.post('/refresh', data: {
                'refreshToken': refreshToken,
              });
              await _loadUserInfo();
              _isAuthenticated = true;
            } catch (e) {
              // No se pudo refrescar, limpiar tokens
              await _storage.clearAll();
              _isAuthenticated = false;
            }
          }
        }

        if (_isAuthenticated) {
          // Cargar habitaciones del usuario
          await _cargarHabitacionesDesdeAPI();
        }
      }
    } catch (e) {
      debugPrint('Error al inicializar: $e');
      await _storage.clearAll();
      _isAuthenticated = false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadUserInfo() async {
    try {
      final userInfo = await _apiService.getUserInfo();
      final email = userInfo['email'] as String;
      final userId = await _storage.getUserId() ?? email;

      _usuario = User(
        id: userId,
        nombre: email.split('@')[0], // Usar parte del email como nombre temporal
        email: email,
        telefono: '',
        idioma: 'es',
      );

      await _storage.saveUserEmail(email);
    } catch (e) {
      debugPrint('Error loading user info: $e');
      rethrow;
    }
  }

  // Login
  Future<bool> login(String email, String password, {String? twoFactorCode}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = LoginRequest(
        email: email,
        password: password,
        twoFactorCode: twoFactorCode,
      );

      final tokenResponse = await _apiService.login(request);

      // Guardar tokens en almacenamiento seguro
      await _storage.saveTokens(tokenResponse);

      // Cargar información del usuario
      await _loadUserInfo();

      // Guardar user ID
      await _storage.saveUserId(_usuario!.id);

      _isAuthenticated = true;

      // Cargar habitaciones asignadas
      await _cargarHabitacionesDesdeAPI();

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado al iniciar sesión';
      debugPrint('Error en login: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Register
  Future<bool> register(String email, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(
        email: email,
        password: password,
      );

      await _apiService.register(request);

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado al registrarse';
      debugPrint('Error en register: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Forgot Password
  Future<bool> forgotPassword(String email) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ForgotPasswordRequest(email: email);
      await _apiService.forgotPassword(request);

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al solicitar recuperación de contraseña';
      debugPrint('Error en forgotPassword: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Reset Password
  Future<bool> resetPassword(String email, String resetCode, String newPassword) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = ResetPasswordRequest(
        email: email,
        resetCode: resetCode,
        newPassword: newPassword,
      );
      await _apiService.resetPassword(request);

      _isLoading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Error al resetear contraseña';
      debugPrint('Error en resetPassword: $e');
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Simular carga de habitaciones desde API
  Future<void> _cargarHabitacionesDesdeAPI() async {
    // Simular delay de red
    await Future.delayed(const Duration(milliseconds: 500));

    final ahora = DateTime.now();

    // Generar habitaciones dummy (como si vinieran de una API)
    _habitaciones = [
      Reserva(
        id: '1',
        numeroReserva: 'RES-2024-001234',
        idUsuario: _usuario!.id,
        numeroHabitacion: '305',
        tipoHabitacion: 'Suite Deluxe',
        fechaEntrada: ahora,
        fechaSalida: ahora.add(const Duration(days: 3)),
        pinAcceso: '847392',
        estado: 'activa',
      ),
      Reserva(
        id: '2',
        numeroReserva: 'RES-2024-001235',
        idUsuario: _usuario!.id,
        numeroHabitacion: '412',
        tipoHabitacion: 'Habitación Standard',
        fechaEntrada: ahora,
        fechaSalida: ahora.add(const Duration(days: 2)),
        pinAcceso: '563829',
        estado: 'activa',
      ),
      Reserva(
        id: '3',
        numeroReserva: 'RES-2024-001236',
        idUsuario: _usuario!.id,
        numeroHabitacion: '528',
        tipoHabitacion: 'Suite Presidencial',
        fechaEntrada: ahora.add(const Duration(days: 5)),
        fechaSalida: ahora.add(const Duration(days: 8)),
        pinAcceso: '192847',
        estado: 'pendiente',
      ),
    ];
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();

    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _usuario = null;
    _habitaciones = [];
    _isAuthenticated = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Actualizar perfil
  Future<void> actualizarPerfil(User nuevoUsuario) async {
    _usuario = nuevoUsuario;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_nombre', nuevoUsuario.nombre);
    await prefs.setString('user_email', nuevoUsuario.email);
    await prefs.setString('user_telefono', nuevoUsuario.telefono);
    await prefs.setString('user_idioma', nuevoUsuario.idioma);

    notifyListeners();
  }
}
