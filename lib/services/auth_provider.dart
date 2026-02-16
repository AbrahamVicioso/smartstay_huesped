import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/huesped.dart';
import '../models/reserva.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/forgot_password_request.dart';
import '../models/auth/reset_password_request.dart';
import '../models/auth/auth_exception.dart';
import 'api_service.dart';
import 'api/huespedes_service.dart';
import 'secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider with ChangeNotifier {
  User? _usuario;
  Huesped? _huesped;
  List<Reserva> _habitaciones = [];
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;

  final _apiService = ApiService();
  final _huespedesService = HuespedesService();
  final _storage = SecureStorageService();

  User? get usuario => _usuario;
  Huesped? get huesped => _huesped;
  List<Reserva> get habitaciones => _habitaciones;
  Reserva? get reservaActual =>
      _habitaciones.isNotEmpty ? _habitaciones.first : null;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Returns the guest's full name from huesped data, or falls back to user name
  String get nombreHuesped {
    if (_huesped != null && _huesped!.nombreCompleto.isNotEmpty) {
      return _huesped!.nombreCompleto;
    }
    return _usuario?.nombre ?? 'Usuario';
  }

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
              await _apiService.dio.post(
                '/refresh',
                data: {'refreshToken': refreshToken},
              );
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
          // Cargar datos del huesped
          await _loadHuespedData();
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
      final accessToken = await _storage.getAccessToken();

      if (accessToken == null) {
        throw Exception('No access token found');
      }

      // Decodificar el JWT para obtener la info del usuario
      final decodedToken = JwtDecoder.decode(accessToken);

      debugPrint('[DEBUG] JWT claims: $decodedToken');

      final email = decodedToken['email'] as String? ??
          decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/emailaddress'] as String? ??
          decodedToken['sub'] as String? ??
          '';

      // Try multiple claim names for user ID (ASP.NET Identity uses nameidentifier)
      final userId = decodedToken['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] as String? ??
          decodedToken['nameid'] as String? ??
          decodedToken['sub'] as String? ??
          decodedToken['jti'] as String? ??
          email;

      _usuario = User(
        id: userId,
        nombre: email.split('@')[0],
        email: email,
        telefono: '',
        idioma: 'es',
      );

      await _storage.saveUserEmail(email);
      debugPrint('[DEBUG] Usuario cargado desde JWT - email: $email, userId: $userId');
    } catch (e) {
      debugPrint('Error loading user info from JWT: $e');
      rethrow;
    }
  }

  /// Load huesped data from API
  Future<void> _loadHuespedData() async {
    if (_usuario == null) return;

    try {
      _huesped = await _huespedesService.getHuespedByUsuarioId(_usuario!.id);
      if (_huesped != null) {
        debugPrint('[DEBUG] Huesped cargado: ${_huesped!.nombreCompleto}');
        // Update user name with huesped name
        _usuario = _usuario!.copyWith(nombre: _huesped!.nombreCompleto);
      } else {
        debugPrint('[DEBUG] No se encontró perfil de huesped para este usuario');
      }
    } catch (e) {
      debugPrint('[DEBUG] Error cargando datos de huesped: $e');
    }
  }

  /// Reload huesped data (e.g. after editing profile)
  Future<void> reloadHuespedData() async {
    await _loadHuespedData();
    notifyListeners();
  }

  // Login
  Future<bool> login(
    String email,
    String password, {
    String? twoFactorCode,
  }) async {
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

      final savedToken = await _storage.getAccessToken();
      debugPrint('[DEBUG] Token guardado: $savedToken');
      debugPrint('[DEBUG] Token original: ${tokenResponse.accessToken}');

      // Cargar información del usuario
      await _loadUserInfo();

      // Guardar user ID
      await _storage.saveUserId(_usuario!.id);

      _isAuthenticated = true;

      // Cargar datos del huesped
      await _loadHuespedData();

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

  // Register - now also creates huesped record
  Future<bool> register(String email, String password, {String? nombreCompleto}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final request = RegisterRequest(email: email, password: password);

      await _apiService.register(request);

      // After successful registration, login to get the userId
      try {
        final loginRequest = LoginRequest(email: email, password: password);
        final tokenResponse = await _apiService.login(loginRequest);
        await _storage.saveTokens(tokenResponse);

        // Load user info to get the userId
        await _loadUserInfo();

        if (_usuario != null) {
          // Create huesped record with the new userId
          final huesped = Huesped(
            usuarioId: _usuario!.id,
            nombreCompleto: nombreCompleto ?? email.split('@')[0],
            tipoDocumento: 'Cedula',
            numeroDocumento: '',
            nacionalidad: 'Dominicana',
            fechaNacimiento: DateTime(2000, 1, 1),
            correoElectronico: email,
            esVip: false,
          );

          final createdHuesped = await _huespedesService.createHuesped(huesped);
          if (createdHuesped != null) {
            debugPrint('[DEBUG] Huesped creado exitosamente: ${createdHuesped.nombreCompleto}');
          } else {
            debugPrint('[DEBUG] No se pudo crear el registro de huesped');
          }
        }

        // Logout after creating huesped - user should login manually
        await _storage.clearAll();
        _usuario = null;
        _huesped = null;
        _isAuthenticated = false;
      } catch (e) {
        debugPrint('[DEBUG] Error al crear huesped después del registro: $e');
        // Registration was successful even if huesped creation failed
      }

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
  Future<bool> resetPassword(
    String email,
    String resetCode,
    String newPassword,
  ) async {
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
    _huesped = null;
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

  /// Update huesped data via API
  Future<bool> updateHuesped(Huesped updatedHuesped) async {
    if (updatedHuesped.huespedId == null) return false;

    try {
      final result = await _huespedesService.updateHuesped(
        updatedHuesped.huespedId!,
        updatedHuesped,
      );

      if (result != null) {
        _huesped = result;
        // Also update user name
        _usuario = _usuario?.copyWith(nombre: result.nombreCompleto);
        notifyListeners();
        return true;
      }

      // Even if result is null, try to reload
      await reloadHuespedData();
      return true;
    } catch (e) {
      debugPrint('[DEBUG] Error actualizando huesped: $e');
      return false;
    }
  }
}
