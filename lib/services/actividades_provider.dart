import 'package:flutter/foundation.dart';
import '../models/actividad.dart';
import '../models/api/actividad_recreativa.dart';
import 'api/actividades_recreativas_service.dart';

class ActividadesProvider with ChangeNotifier {
  List<Actividad> _actividades = [];
  final List<ReservaActividad> _misReservas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _actividadesService = ActividadesRecreativasService();

  List<Actividad> get actividades => _actividades;
  List<ReservaActividad> get misReservas => _misReservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Cargar actividades desde la API real
  Future<void> cargarActividades() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final actividadesApi = await _actividadesService.getAll();
      debugPrint('[ActividadesProvider] Actividades cargadas: ${actividadesApi.length}');

      // Convert API model to local Actividad model
      _actividades = actividadesApi
          .where((a) => a.estaActiva) // Only show active activities
          .map((a) => _convertirActividadRecreativa(a))
          .toList();

      debugPrint('[ActividadesProvider] Actividades activas: ${_actividades.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ActividadesProvider] Error cargando actividades: $e');
      _errorMessage = 'Error al cargar actividades: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert ActividadRecreativa (API model) to Actividad (local model)
  Actividad _convertirActividadRecreativa(ActividadRecreativa api) {
    return Actividad(
      id: api.actividadId.toString(),
      nombre: api.nombreActividad,
      descripcion: api.descripcion ?? 'Sin descripción',
      icono: _getIconForCategory(api.categoria),
      categoria: api.categoria.toLowerCase(),
      horarioApertura: _formatTimeSpan(api.horaApertura),
      horarioCierre: _formatTimeSpan(api.horaCierre),
      capacidadMaxima: api.capacidadMaxima,
      requiereReserva: api.requiereReserva,
      precio: api.precioPorPersona > 0 ? api.precioPorPersona : null,
    );
  }

  /// Map category to icon name
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

  /// Format TimeSpan string (e.g. "09:00:00") to "09:00"
  String _formatTimeSpan(String timeSpan) {
    try {
      final parts = timeSpan.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
      return timeSpan;
    } catch (e) {
      return timeSpan;
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

  /// Get unique categories from loaded activities
  List<String> get categorias {
    return _actividades.map((a) => a.categoria).toSet().toList();
  }
}
