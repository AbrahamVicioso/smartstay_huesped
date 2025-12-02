import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import '../models/reserva.dart';

class AuthProvider with ChangeNotifier {
  User? _usuario;
  List<Reserva> _habitaciones = [];
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get usuario => _usuario;
  List<Reserva> get habitaciones => _habitaciones;
  Reserva? get reservaActual => _habitaciones.isNotEmpty ? _habitaciones.first : null;
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

        // Cargar habitaciones del usuario
        await _cargarHabitacionesDesdeAPI();
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

      // Datos de ejemplo del usuario
      _usuario = User(
        id: '1',
        nombre: 'Juan Pérez',
        email: email,
        telefono: '+1 809-555-0123',
        idioma: 'es',
      );

      _isAuthenticated = true;

      // Cargar habitaciones asignadas desde "API" (datos dummy)
      await _cargarHabitacionesDesdeAPI();

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
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    _usuario = null;
    _habitaciones = [];
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
}
