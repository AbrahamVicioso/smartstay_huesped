
import 'package:flutter/foundation.dart';
import '../models/actividad.dart';
import '../models/api/actividad_recreativa.dart';
import '../models/api/reserva_actividad.dart';
import 'api/actividades_recreativas_service.dart';
import 'api/reservas_actividades_service.dart';
import 'api/huespedes_service.dart';

class ActividadesProvider with ChangeNotifier {
  List<Actividad> _actividades = [];
  final Map<int, String> _actividadNombres = {};
  final List<ReservaActividad> _misReservas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _actividadesService = ActividadesRecreativasService();
  final _reservasService = ReservasActividadesService();
  final _huespedesService = HuespedesService();

  List<Actividad> get actividades => _actividades;
  List<ReservaActividad> get misReservas => _misReservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  String getNombreActividad(int actividadId) =>
      _actividadNombres[actividadId] ?? 'Actividad #$actividadId';

  
  Future<void> cargarActividades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actividadesApi = await _actividadesService.getAll();
      debugPrint('[ActividadesProvider] Actividades recibidas de API: ${actividadesApi.length}');

      
      _actividades = [];
      _actividadNombres.clear();
      for (var a in actividadesApi) {
        _actividadNombres[a.actividadId] = a.nombreActividad ?? 'Actividad #${a.actividadId}';
        try {
          if (a.estaActiva) {
            final actividad = _convertirActividadRecreativa(a);
            _actividades.add(actividad);
          }
        } catch (e) {
          debugPrint('[ActividadesProvider] Error convirtiendo actividad ${a.actividadId}: $e');
        }
      }

      debugPrint('[ActividadesProvider] Actividades activas cargadas: ${_actividades.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ActividadesProvider] Error cargando actividades: $e');
      _errorMessage = 'Error al cargar actividades';
      _actividades = []; 
      _isLoading = false;
      notifyListeners();
    }
  }

  
  Actividad _convertirActividadRecreativa(ActividadRecreativa api) {
    return Actividad(
      id: api.actividadId.toString(),
      nombre: api.nombreActividad ?? 'Sin nombre',
      descripcion: api.descripcion ?? 'Sin descripción',
      icono: _getIconForCategory(api.categoria ?? ''),
      categoria: (api.categoria ?? 'general').toLowerCase(),
      horarioApertura: api.horaApertura ?? '08:00:00',
      horarioCierre: api.horaCierre ?? '22:00:00',
      capacidadMaxima: api.capacidadMaxima ?? 0,
      requiereReserva: api.requiereReserva ?? false,
      precio: (api.precioPorPersona != null && api.precioPorPersona! > 0)
          ? api.precioPorPersona
          : null,
      ubicacion: api.ubicacion,
      duracionMinutos: api.duracionMinutos,
    );
  }

  
  String _getIconForCategory(String categoria) {
    final cat = categoria.toLowerCase();
    if (cat.contains('gimnasio') || cat.contains('fitness')) return 'fitness_center';
    if (cat.contains('spa') || cat.contains('wellness')) return 'spa';
    if (cat.contains('restaurante') || cat.contains('comida') || cat.contains('food')) return 'restaurant';
    if (cat.contains('piscina') || cat.contains('pool')) return 'pool';
    if (cat.contains('tour') || cat.contains('excursion')) return 'tour';
    if (cat.contains('yoga') || cat.contains('meditacion')) return 'self_improvement';
    return 'local_activity';
  }

  Future<int?> _getHuespedId() async {
    try {
      final huesped = await _huespedesService.getHuespedMe();
      return huesped?.huespedId;
    } catch (e) {
      debugPrint('[ActividadesProvider] Error getting huespedId: $e');
      return null;
    }
  }

  
  Future<bool> reservarActividad({
    required String idActividad,
    required String idUsuario,
    required DateTime fecha,
    required String hora,
    required int numeroPersonas,
    String? notas,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      final huespedId = await _getHuespedId();
      if (huespedId == null) {
        _errorMessage = 'No se encontró el perfil de huésped';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final actividad = _obtenerActividadPorId(idActividad);
      final precioPorPersona = actividad?.precio ?? 0.0;
      final montoTotal = precioPorPersona * numeroPersonas;

      final reserva = await _reservasService.crearReservaActividad(
        actividadId: int.parse(idActividad),
        huespedId: huespedId,
        fecha: fecha,
        hora: hora,
        personas: numeroPersonas,
        monto: montoTotal,
        notas: notas,
      );

      if (reserva != null) {
  final nuevaReserva = ReservaActividad(
    id: reserva.reservaActividadId.toString(),
    idActividad: idActividad,
    idUsuario: idUsuario,
    fecha: fecha,
    hora: hora,
    numeroPersonas: numeroPersonas,
    estado: reserva.estado,
  );

  _misReservas.add(nuevaReserva);
  
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Error al crear la reserva';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[ActividadesProvider] Error reservando actividad: $e');
      _errorMessage = 'Error al crear la reserva: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  
  Future<bool> cancelarReserva(String idReserva) async {
    try {
      _isLoading = true;
      notifyListeners();

      final success = await _reservasService.cancelarReservaActividad(
        int.parse(idReserva),
      );

      if (success) {
        _misReservas.removeWhere((r) => r.id == idReserva);
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = 'Error al cancelar la reserva';
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      debugPrint('[ActividadesProvider] Error cancelando reserva: $e');
      _errorMessage = 'Error al cancelar la reserva: $e';
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Actividad? _obtenerActividadPorId(String id) {
    try {
      return _actividades.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  Actividad? obtenerActividadPorId(String id) {
    return _obtenerActividadPorId(id);
  }

  List<Actividad> filtrarPorCategoria(String categoria) {
    return _actividades.where((a) => a.categoria == categoria).toList();
  }

  List<String> get categorias {
    return _actividades.map((a) => a.categoria).toSet().toList();
  }
}