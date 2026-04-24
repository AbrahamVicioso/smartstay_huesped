import 'package:flutter/foundation.dart';
import 'package:smartstay_huesped/services/api/reservas_actividades_service.dart';
import '../models/api/reserva_actividad.dart';
import '../services/api/huespedes_service.dart';

class ReservasActividadesProvider with ChangeNotifier {
  List<ReservaActividadApi> _misReservas = [];

  bool _isLoading = false;
  String? _errorMessage;

  final ReservasActividadesService _reservasService = ReservasActividadesService();
  final HuespedesService _huespedesService = HuespedesService();

  List<ReservaActividadApi> get misReservas => _misReservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarMisReservas() async {
    _isLoading = true;
    _errorMessage = null;
    _misReservas = [];
    notifyListeners();

    try {
      // Get huesped via /Huesped/me (JWT-based, no userId lookup needed)
      final huesped = await _huespedesService.getHuespedMe();
      debugPrint('[ReservasActividadesProvider] HuespedId: ${huesped?.huespedId}');

      if (huesped == null) {
        _misReservas = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // /ReservasActividades/me returns only current user's activities
      _misReservas = await _reservasService.getMisActividades(huesped.huespedId ?? 0);

      debugPrint('[ReservasActividadesProvider] Reservas cargadas: ${_misReservas.length}');
      for (var r in _misReservas) {
        debugPrint('[ReservasActividadesProvider] ID: ${r.reservaActividadId} - Estado: ${r.estado}');
      }
    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[ReservasActividadesProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reservas activas
  List<ReservaActividadApi> get reservasActivas {
    final activas = _misReservas.where((r) {
      final estado = r.estado.toLowerCase();
      return estado == 'confirmada' ||
          estado == 'checkin' ||
          estado == 'pendiente';
    }).toList();
    
    debugPrint('[ReservasActividadesProvider] Reservas activas: ${activas.length}');
    return activas;
  }

 
  List<ReservaActividadApi> get reservasPasadas {
    final pasadas = _misReservas.where((r) {
      final estado = r.estado.toLowerCase();
      return estado == 'checkout' ||
          estado == 'cancelada' ||
          estado == 'completada';
    }).toList();
    
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