import 'package:flutter/foundation.dart';
import '../models/notificacion.dart';

class NotificacionesProvider with ChangeNotifier {
  List<Notificacion> _notificaciones = [];
  bool _notificacionesActivas = true;
  bool _modoNoMolestar = false;
  String _horaInicioNoMolestar = '22:00';
  String _horaFinNoMolestar = '08:00';

  List<Notificacion> get notificaciones => _notificaciones;
  List<Notificacion> get notificacionesNoLeidas =>
      _notificaciones.where((n) => !n.leida).toList();
  int get cantidadNoLeidas => notificacionesNoLeidas.length;
  bool get notificacionesActivas => _notificacionesActivas;
  bool get modoNoMolestar => _modoNoMolestar;
  String get horaInicioNoMolestar => _horaInicioNoMolestar;
  String get horaFinNoMolestar => _horaFinNoMolestar;

  // Cargar notificaciones
  Future<void> cargarNotificaciones(String idUsuario) async {
    try {
      await Future.delayed(const Duration(seconds: 1));

      // Datos de ejemplo
      _notificaciones = [
        Notificacion(
          id: '1',
          idUsuario: idUsuario,
          titulo: 'Bienvenido a SmartStay',
          mensaje: 'Gracias por elegir nuestro hotel. Disfrute su estadía.',
          fecha: DateTime.now().subtract(const Duration(hours: 2)),
          tipo: 'sistema',
          leida: false,
        ),
        Notificacion(
          id: '2',
          idUsuario: idUsuario,
          titulo: 'Acceso de Personal de Limpieza',
          mensaje: 'El personal de limpieza accedió a su habitación 305.',
          fecha: DateTime.now().subtract(const Duration(hours: 1)),
          tipo: 'acceso',
          leida: false,
          datos: {
            'personal': 'María González',
            'motivo': 'Limpieza diaria',
            'hora': '10:30 AM',
          },
        ),
        Notificacion(
          id: '3',
          idUsuario: idUsuario,
          titulo: 'Recordatorio: Reserva de Spa',
          mensaje: 'Su cita en el spa es en 1 hora (3:00 PM)',
          fecha: DateTime.now().subtract(const Duration(minutes: 30)),
          tipo: 'recordatorio',
          leida: true,
        ),
      ];

      notifyListeners();
    } catch (e) {
      debugPrint('Error al cargar notificaciones: $e');
    }
  }

  // Agregar notificación
  void agregarNotificacion(Notificacion notificacion) {
    _notificaciones.insert(0, notificacion);
    notifyListeners();
  }

  // Marcar como leída
  void marcarComoLeida(String idNotificacion) {
    final index = _notificaciones.indexWhere((n) => n.id == idNotificacion);
    if (index != -1) {
      _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
      notifyListeners();
    }
  }

  // Marcar todas como leídas
  void marcarTodasComoLeidas() {
    _notificaciones = _notificaciones
        .map((n) => n.copyWith(leida: true))
        .toList();
    notifyListeners();
  }

  // Eliminar notificación
  void eliminarNotificacion(String idNotificacion) {
    _notificaciones.removeWhere((n) => n.id == idNotificacion);
    notifyListeners();
  }

  // Alternar notificaciones
  void toggleNotificaciones(bool valor) {
    _notificacionesActivas = valor;
    notifyListeners();
  }

  // Alternar modo No Molestar
  void toggleModoNoMolestar(bool valor) {
    _modoNoMolestar = valor;
    notifyListeners();
  }

  // Configurar horario No Molestar
  void configurarHorarioNoMolestar(String inicio, String fin) {
    _horaInicioNoMolestar = inicio;
    _horaFinNoMolestar = fin;
    notifyListeners();
  }

  // Simular notificación de acceso
  void simularNotificacionAcceso({
    required String idUsuario,
    required String personal,
    required String motivo,
  }) {
    if (!_notificacionesActivas || _modoNoMolestar) return;

    final nuevaNotificacion = Notificacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idUsuario: idUsuario,
      titulo: 'Acceso de Personal Autorizado',
      mensaje: '$personal accedió a su habitación.',
      fecha: DateTime.now(),
      tipo: 'acceso',
      datos: {
        'personal': personal,
        'motivo': motivo,
        'hora': '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      },
    );

    agregarNotificacion(nuevaNotificacion);
  }
}
