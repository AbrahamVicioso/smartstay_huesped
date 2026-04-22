import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:smartstay_huesped/services/api/auth_service.dart';
import '../models/user.dart';
import '../models/huesped.dart';
import '../models/reserva.dart';
import '../models/api/habitacion.dart';
import '../models/api/reserva_api.dart';
import '../models/auth/login_request.dart';
import '../models/auth/register_request.dart';
import '../models/auth/forgot_password_request.dart';
import '../models/auth/reset_password_request.dart';
import '../models/auth/auth_exception.dart';
import 'api/api_service.dart';
import 'api/huespedes_service.dart';
import 'api/habitacion_service.dart';
import 'api/reservas_service.dart';
import 'api/secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class AuthProvider with ChangeNotifier {
  User? _usuario;
  Huesped? _huesped;
  List<Reserva> _habitaciones = [];
  List<Habitacion> _habitacionesDetalladas = [];
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _errorMessage;
  bool _hasCheckedIn = false; // Track if user has completed check-in
  int? _reservaIdCheckIn; // Track which reservation was used for check-in

  final _apiService = ApiService();
  final _huespedesService = HuespedesService();
  final _habitacionService = HabitacionService();
  final _reservasService = ReservasService();
  final _storage = SecureStorageService();

  User? get usuario => _usuario;
  Huesped? get huesped => _huesped;
  List<Reserva> get habitaciones => _habitaciones;
  List<Habitacion> get habitacionesDetalladas => _habitacionesDetalladas;
  Reserva? get reservaActual =>
      _habitaciones.isNotEmpty ? _habitaciones.first : null;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasCheckedIn => _hasCheckedIn;
  
  // Returns true if user can access room features (after check-in)
  bool get puedeAccederHabitacion => _hasCheckedIn && _habitacionesDetalladas.isNotEmpty;
  int? get reservaIdCheckIn => _reservaIdCheckIn;

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
          // Cargar estado del check-in desde SharedPreferences
          await _cargarCheckInStatus();
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
 Future<bool> register(
  String email,
  String password, {
  required String nombreCompleto,
  required String numeroDocumento,
  int tipoDocumentoId = 1,
  String nacionalidad = 'Dominicana',
}) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    // 1. Crear usuario en Auth
    await _apiService.register(RegisterRequest(email: email, password: password));
    debugPrint('[AuthProvider] Usuario registrado en Auth');

    // 2. Login temporal para obtener token y userId
    final tokenResponse = await _apiService.login(
      LoginRequest(email: email, password: password),
    );
    final token = tokenResponse.accessToken;
    final decoded = JwtDecoder.decode(token);
    final userId = decoded[
          'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
        ] as String? ??
        decoded['sub'] as String? ??
        '';

    debugPrint('[AuthProvider] UserId: $userId');

    // 3. Asignar rol Guest
    final _authService = AuthService();
    final rolOk = await _authService.asignarRol(userId, 'Guest', token: token);
    debugPrint('[AuthProvider] Rol Guest asignado: $rolOk');

    // 4. Crear huésped en tabla Huespedes
    final huespedOk = await _authService.crearHuesped(
      {
        'correoElectronico': email,
        'nombreCompleto': nombreCompleto,
        'tipoDocumentoId': tipoDocumentoId,
        'numeroDocumento': numeroDocumento,
        'nacionalidad': nacionalidad,
        'fechaNacimiento': '2000-01-01T00:00:00Z',
        'contactoEmergencia': null,
        'telefonoEmergencia': null,
        'esVip': false,
        'preferenciasAlimentarias': null,
        'notasEspeciales': null,
      },
      token: token,
    );
    debugPrint('[AuthProvider] Huesped creado: $huespedOk');

    // 5. Limpiar — usuario hace login manual
    await _storage.clearAll();

    _isLoading = false;
    notifyListeners();
    return true;
  } on AuthException catch (e) {
    _errorMessage = e.toString();
    _isLoading = false;
    notifyListeners();
    return false;
  } catch (e) {
    _errorMessage = 'Error durante el registro: $e';
    debugPrint('[AuthProvider] register error: $e');
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

  // Helper function to check if reserva has check-in (handles different formats from backend)
  bool _reservaTieneCheckIn(ReservaApi reserva) {
    // Check if checkInRealizado is not null
    if (reserva.checkInRealizado != null) {
      return true;
    }
    // Additional check: if the reserva state is 'Activa', consider it as having check-in
    if (reserva.estado.toLowerCase() == 'activa') {
      return true;
    }
    return false;
  }

  // Cargar habitaciones reales desde API
  Future<void> _cargarHabitacionesDesdeAPI() async {
    try {
      debugPrint('[AuthProvider] Cargando habitaciones desde API...');

      // 1. Obtener el huesped actual
      if (_huesped == null || _huesped!.huespedId == null) {
        debugPrint('[AuthProvider] No hay huesped, no se pueden cargar habitaciones');
        _habitacionesDetalladas = [];
        notifyListeners();
        return;
      }

      // 2. Obtener reservas del huesped
      final reservas = await _reservasService.getByHuespedId(_huesped!.huespedId!);
      debugPrint('[AuthProvider] Reservas encontradas: ${reservas.length}');

      if (reservas.isEmpty) {
        _habitacionesDetalladas = [];
        notifyListeners();
        return;
      }

      // 3. Obtener detalles de cada habitación
      final List<Habitacion> habitaciones = [];
      
      for (final reserva in reservas) {
      
if (reserva.checkInRealizado == null && reserva.estado.toLowerCase() != 'pendiente') {
  debugPrint('[AuthProvider] Saltando reserva ${reserva.reservaId} - No está lista');
  continue;
}
        
        // También filtramos las que ya tienen check-out realizado
        if (reserva.checkOutRealizado != null) {
          debugPrint('[AuthProvider] Saltando reserva ${reserva.reservaId} - CheckOutRealizado ya existe');
          continue;
        }
        
        // Obtener detalles de la habitación
        final habitacion = await _habitacionService.getById(reserva.habitacionId);
        
        if (habitacion != null) {
          // Agregar información de la reserva a la habitación
          final habitacionConReserva = habitacion.copyWithReserva(
            reservaId: reserva.reservaId,
            fechaCheckIn: reserva.fechaCheckIn,
            fechaCheckOut: reserva.fechaCheckOut,
            reservaEstado: reserva.estado,
            pinAcceso: _generarPinAleatorio(), // El PIN se genera o viene del backend
          );
          habitaciones.add(habitacionConReserva);
          debugPrint('[AuthProvider] Habitación añadida: ${habitacion.numeroHabitacion} (CheckIn: ${reserva.checkInRealizado})');
        }
      }

      _habitacionesDetalladas = habitaciones;
      
      // También actualizar la lista de Reserva para compatibilidad
      _habitaciones = reservas.map((r) => Reserva(
        id: r.reservaId.toString(),
        numeroReserva: 'RES-${r.reservaId}',
        idUsuario: _usuario!.id,
        numeroHabitacion: habitaciones.firstWhere(
          (h) => h.reservaId == r.reservaId,
          orElse: () => Habitacion(
            habitacionId: r.habitacionId,
            hotelId: 0,
            numeroHabitacion: '${r.habitacionId}',
            tipoHabitacion: 'Habitación',
            piso: 0,
            capacidadMaxima: 0,
            precioPorNoche: 0,
            estado: '',
            estaDisponible: false,
          ),
        ).numeroHabitacion,
        tipoHabitacion: 'Habitación',
        fechaEntrada: r.fechaCheckIn,
        fechaSalida: r.fechaCheckOut,
        pinAcceso: _generarPinAleatorio(),
        estado: r.estado,
        numeroHuespedes: r.numeroHuespedes,
        numeroNinos: r.numeroNinos,
      )).toList();

      debugPrint('[AuthProvider] Total habitaciones cargadas: ${_habitacionesDetalladas.length}');
      notifyListeners();

    } catch (e) {
      debugPrint('[AuthProvider] Error cargando habitaciones: $e');
      _habitacionesDetalladas = [];
      notifyListeners();
    }
  }

  // Generar PIN aleatorio de 6 dígitos
  String _generarPinAleatorio() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }

  // Mark check-in as completed and load rooms
  Future<void> completarCheckIn(int reservaId) async {
    _hasCheckedIn = true;
    _reservaIdCheckIn = reservaId;
    
    // Save check-in status to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('hasCheckedIn', true);
    await prefs.setInt('reservaIdCheckIn', reservaId);
    
    notifyListeners();
    
    // After check-in, try to load rooms
    await _cargarHabitacionesDesdeAPI();
  }
  
  // Load check-in status from SharedPreferences and verify with API
  Future<void> _cargarCheckInStatus() async {
    // First, check local storage
    final prefs = await SharedPreferences.getInstance();
    final localHasCheckedIn = prefs.getBool('hasCheckedIn') ?? false;
    _reservaIdCheckIn = prefs.getInt('reservaIdCheckIn');
    
    // If local storage says check-in was done, verify with API
    if (localHasCheckedIn) {
      // Try to load rooms from API to verify check-in status
      try {
        if (_huesped != null && _huesped!.huespedId != null) {
          final reservas = await _reservasService.getByHuespedId(_huesped!.huespedId!);
          
          // Check if there's any reservation with check-in done and no check-out
          final hasActiveCheckIn = reservas.any((r) => 
            _reservaTieneCheckIn(r) && r.checkOutRealizado == null
          );
          
          if (hasActiveCheckIn) {
            _hasCheckedIn = true;
            debugPrint('[AuthProvider] Check-in verificado con API: true');
            // Cargar habitaciones ya que el check-in está activo
            await _cargarHabitacionesDesdeAPI();
          } else {
            // Check-in was done but check-out was also done, reset status
            _hasCheckedIn = false;
            _reservaIdCheckIn = null;
            await prefs.remove('hasCheckedIn');
            await prefs.remove('reservaIdCheckIn');
            debugPrint('[AuthProvider] Check-in expirado (check-out realizado), estado reseteado');
          }
        }
      } catch (e) {
        // If API fails, trust local storage and try to load rooms anyway
        _hasCheckedIn = localHasCheckedIn;
        debugPrint('[AuthProvider] Error verificando check-in con API, intentando cargar habitaciones: $e');
        await _cargarHabitacionesDesdeAPI();
      }
    } else {
      _hasCheckedIn = false;
    }
    
    debugPrint('[AuthProvider] Check-in status loaded: $_hasCheckedIn, reservaId: $_reservaIdCheckIn');
  }
  
  // Reset check-in status (for manual reset only)
  void resetCheckIn() {
    _hasCheckedIn = false;
    _reservaIdCheckIn = null;
    notifyListeners();
  }

  // Logout
  Future<void> logout() async {
    await _storage.clearAll();

    // NO清除 SharedPreferences 中的 check-in 状态，这样用户退出后重新登录时仍会显示已 check-in
    final prefs = await SharedPreferences.getInstance();
    // 只清除与登录相关的偏好设置，保留 check-in 状态
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('token_expiry');
    await prefs.remove('user_id');
    await prefs.remove('user_nombre');
    await prefs.remove('user_email');
    await prefs.remove('user_telefono');
    await prefs.remove('user_idioma');
    // 保留 hasCheckedIn 和 reservaIdCheckIn

    _usuario = null;
    _huesped = null;
    _habitaciones = [];
    _habitacionesDetalladas = [];
    _isAuthenticated = false;
    _errorMessage = null;
    // 不重置 _hasCheckedIn，保留 check-in 状态
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

  /// Verifica si ya existe un huésped con el número de documento
  Future<bool> documentoExiste(String numeroDocumento) async {
    try {
      return await _huespedesService.documentoExiste(numeroDocumento);
    } catch (e) {
      debugPrint('[DEBUG] Error verificando documento: $e');
      return false;
    }
  }
}
