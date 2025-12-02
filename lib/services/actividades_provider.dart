import 'package:flutter/foundation.dart';
import '../models/actividad.dart';

class ActividadesProvider with ChangeNotifier {
  List<Actividad> _actividades = [];
  List<ReservaActividad> _misReservas = [];
  bool _isLoading = false;

  List<Actividad> get actividades => _actividades;
  List<ReservaActividad> get misReservas => _misReservas;
  bool get isLoading => _isLoading;

  // Inicializar actividades
  Future<void> cargarActividades() async {
    _isLoading = true;
    notifyListeners();

    try {
      await Future.delayed(const Duration(seconds: 1));

      // Datos de ejemplo
      _actividades = [
        Actividad(
          id: '1',
          nombre: 'Gimnasio',
          descripcion: 'Equipamiento completo de última generación disponible 24/7',
          icono: 'fitness_center',
          categoria: 'gimnasio',
          horarioApertura: '00:00',
          horarioCierre: '23:59',
          capacidadMaxima: 20,
          requiereReserva: false,
        ),
        Actividad(
          id: '2',
          nombre: 'Spa & Wellness',
          descripcion: 'Masajes relajantes, tratamientos faciales y corporales',
          icono: 'spa',
          categoria: 'spa',
          horarioApertura: '09:00',
          horarioCierre: '20:00',
          capacidadMaxima: 8,
          requiereReserva: true,
          precio: 75.00,
        ),
        Actividad(
          id: '3',
          nombre: 'Restaurante Gourmet',
          descripcion: 'Cocina internacional con vista panorámica',
          icono: 'restaurant',
          categoria: 'restaurante',
          horarioApertura: '07:00',
          horarioCierre: '23:00',
          capacidadMaxima: 50,
          requiereReserva: true,
        ),
        Actividad(
          id: '4',
          nombre: 'Piscina Infinity',
          descripcion: 'Piscina climatizada con bar en el agua',
          icono: 'pool',
          categoria: 'piscina',
          horarioApertura: '06:00',
          horarioCierre: '22:00',
          capacidadMaxima: 30,
          requiereReserva: false,
        ),
        Actividad(
          id: '5',
          nombre: 'Tour Ciudad Colonial',
          descripcion: 'Visita guiada por las calles históricas de Santo Domingo',
          icono: 'tour',
          categoria: 'tour',
          horarioApertura: '09:00',
          horarioCierre: '17:00',
          capacidadMaxima: 15,
          requiereReserva: true,
          precio: 45.00,
        ),
        Actividad(
          id: '6',
          nombre: 'Clase de Yoga',
          descripcion: 'Sesiones matutinas de yoga frente al mar',
          icono: 'self_improvement',
          categoria: 'gimnasio',
          horarioApertura: '06:00',
          horarioCierre: '08:00',
          capacidadMaxima: 12,
          requiereReserva: true,
          precio: 25.00,
        ),
      ];

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Realizar reserva de actividad
  Future<bool> reservarActividad({
    required String idActividad,
    required String idUsuario,
    required DateTime fecha,
    required String hora,
    required int numeroPersonas,
  }) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      final nuevaReserva = ReservaActividad(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        idActividad: idActividad,
        idUsuario: idUsuario,
        fecha: fecha,
        hora: hora,
        numeroPersonas: numeroPersonas,
        estado: 'confirmada',
      );

      _misReservas.add(nuevaReserva);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Cancelar reserva
  Future<bool> cancelarReserva(String idReserva) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      _misReservas.removeWhere((r) => r.id == idReserva);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  // Obtener actividad por ID
  Actividad? obtenerActividadPorId(String id) {
    try {
      return _actividades.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  // Filtrar actividades por categoría
  List<Actividad> filtrarPorCategoria(String categoria) {
    return _actividades.where((a) => a.categoria == categoria).toList();
  }
}
