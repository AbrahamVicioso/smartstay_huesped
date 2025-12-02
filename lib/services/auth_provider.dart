import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/reserva.dart';

class AuthProvider with ChangeNotifier {
  User? _usuario;
  Reserva? _reservaActual;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get usuario => _usuario;
  Reserva? get reservaActual => _reservaActual;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  // Inicializar y cargar datos guardados
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = prefs.getString('user_id');

      if (userId != null) {
        // Cargar usuario guardado (en producción vendría de una API)
        _isAuthenticated = true;
        // Datos de ejemplo
        _usuario = User(
          id: userId,
          nombre: prefs.getString('user_nombre') ?? 'Usuario',
          email: prefs.getString('user_email') ?? 'usuario@ejemplo.com',
          telefono: prefs.getString('user_telefono') ?? '',
          idioma: prefs.getString('user_idioma') ?? 'es',
        );
      }
    } catch (e) {
      debugPrint('Error al inicializar: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Login
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Simular llamada a API (2 segundos)
      await Future.delayed(const Duration(seconds: 2));

      // Datos de ejemplo
      _usuario = User(
        id: '1',
        nombre: 'Juan Pérez',
        email: email,
        telefono: '+1 809-555-0123',
        idioma: 'es',
      );

      _isAuthenticated = true;

      // Guardar en SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_id', _usuario!.id);
      await prefs.setString('user_nombre', _usuario!.nombre);
      await prefs.setString('user_email', _usuario!.email);
      await prefs.setString('user_telefono', _usuario!.telefono);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Logout
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _usuario = null;
    _reservaActual = null;
    _isAuthenticated = false;
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

  // Check-in
  Future<bool> realizarCheckin({
    required String numeroReserva,
    required String email,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 2));

      // Generar PIN de 6 dígitos
      final pin = _generarPIN();

      // Datos de ejemplo de reserva
      _reservaActual = Reserva(
        id: '1',
        numeroReserva: numeroReserva,
        idUsuario: _usuario!.id,
        numeroHabitacion: '305',
        tipoHabitacion: 'Suite Deluxe',
        fechaEntrada: DateTime.now(),
        fechaSalida: DateTime.now().add(const Duration(days: 3)),
        pinAcceso: pin,
        estado: 'activa',
      );

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('reserva_id', _reservaActual!.id);

      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  String _generarPIN() {
    final random = DateTime.now().millisecondsSinceEpoch % 1000000;
    return random.toString().padLeft(6, '0');
  }
}
