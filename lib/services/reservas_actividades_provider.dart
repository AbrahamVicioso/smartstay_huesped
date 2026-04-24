import 'package:flutter/foundation.dart';
import 'package:smartstay_huesped/services/api/reservas_actividades_service.dart';
import '../models/api/reserva_actividad.dart';
import '../services/api/huespedes_service.dart';
import '../services/api/actividades_recreativas_service.dart';

class ReservasActividadesProvider with ChangeNotifier {
  List<ReservaActividadApi> _misReservas = [];
  final Map<int, String> _actividadNombres = {};

  bool _isLoading = false;
  String? _errorMessage;

  final ReservasActividadesService _reservasService = ReservasActividadesService();
  final HuespedesService _huespedesService = HuespedesService();
  final ActividadesRecreativasService _actividadesService = ActividadesRecreativasService();

  List<ReservaActividadApi> get misReservas => _misReservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String getNombreActividad(int actividadId) =>
      _actividadNombres[actividadId] ?? 'Actividad #$actividadId';

  Future<void> cargarMisReservas() async {
    _isLoading = true;
    _errorMessage = null;
    _misReservas = [];
    notifyListeners();

    try {
      final huesped = await _huespedesService.getHuespedMe();
      debugPrint('[ReservasActividadesProvider] HuespedId: ${huesped?.huespedId}');

      if (huesped == null) {
        _misReservas = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      _misReservas = await _reservasService.getMisActividades(huesped.huespedId ?? 0);

      debugPrint('[ReservasActividadesProvider] Reservas cargadas: ${_misReservas.length}');
      for (var r in _misReservas) {
        debugPrint('[ReservasActividadesProvider] ID: ${r.reservaActividadId} - Estado: ${r.estado}');
      }

      // Load activity names as best-effort — failure must not hide reservations
      try {
        final actividades = await _actividadesService.getAll();
        _actividadNombres.clear();
        for (final a in actividades) {
          _actividadNombres[a.actividadId] = a.nombreActividad ?? 'Actividad #${a.actividadId}';
        }
      } catch (e) {
        debugPrint('[ReservasActividadesProvider] No se cargaron nombres de actividades: $e');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[ReservasActividadesProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reservas activas — anything not explicitly completed/cancelled
  List<ReservaActividadApi> get reservasActivas {
    final pasadasEstados = {'checkout', 'cancelada', 'completada'};
    final activas = _misReservas
        .where((r) => !pasadasEstados.contains(r.estado.toLowerCase()))
        .toList();
    debugPrint('[ReservasActividadesProvider] Reservas activas: ${activas.length}');
    return activas;
  }

  List<ReservaActividadApi> get reservasPasadas {
    final pasadasEstados = {'checkout', 'cancelada', 'completada'};
    final pasadas = _misReservas
        .where((r) => pasadasEstados.contains(r.estado.toLowerCase()))
        .toList();
    debugPrint('[ReservasActividadesProvider] Reservas pasadas: ${pasadas.length}');
    return pasadas;
  }

 
  Future<bool> cancelarReserva(int reservaActividadId) async {
  _isLoading = true;
  _errorMessage = null;
  notifyListeners();

  try {
    final success = await _reservasService.cancelarReservaActividad(reservaActividadId);

    if (success) {

      
      await cargarMisReservas();

      
      _misReservas = _misReservas.map((r) {
        if (r.reservaActividadId == reservaActividadId) {
          return r.copyWith(estado: 'cancelada'); 
        }
        return r;
      }).toList();

      notifyListeners();
      return true;
    }

    _errorMessage = 'No se pudo cancelar en el servidor';
    return false;

  } catch (e) {
    _errorMessage = e.toString();
    return false;
  } finally {
    _isLoading = false;
    notifyListeners();
  }
}
}