import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/actividad.dart';
import '../models/api/actividad_recreativa.dart';
import '../models/api/reserva_actividad.dart';
import 'api/actividades_recreativas_service.dart';
import 'api/reservas_service.dart';
import 'api/huespedes_service.dart';
import 'secure_storage_service.dart';

class ActividadesProvider with ChangeNotifier {
  List<Actividad> _actividades = [];
  final List<ReservaActividad> _misReservas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _actividadesService = ActividadesRecreativasService();
  final _reservasService = ReservasService();
  final _huespedesService = HuespedesService();
  final _storage = SecureStorageService();

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

  /// Get HuespedId from userId
  Future<int?> _getHuespedId() async {
    try {
      // 1. Obtener token
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        throw Exception('No hay sesión activa');
      }

      // 2. Decodificar JWT para obtener el GUID del usuario
      final decodedToken = JwtDecoder.decode(accessToken);
      final userId = decodedToken[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
      ] as String?;

      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      // 3. Buscar HuespedId
      final huespedId = await _huespedesService.getHuespedIdByUsuarioId(userId);
      return huespedId;
    } catch (e) {
      debugPrint('[ActividadesProvider] Error getting huespedId: $e');
      return null;
    }
  }

  // Realizar reserva de actividad - calls the API
  Future<bool> reservarActividad({
    required String idActividad,
    required String idUsuario,
    required DateTime fecha,
    required String hora,
    required int numeroPersonas,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Get huespedId
      final huespedId = await _getHuespedId();
      if (huespedId == null) {
        _errorMessage = 'No se encontró el perfil de huésped';
        _isLoading = false;
        notifyListeners();
        return false;
      }

      // Get actividad to calculate price
      final actividad = _obtenerActividadPorId(idActividad);
      final precioPorPersona = actividad?.precio ?? 0.0;
      final montoTotal = precioPorPersona * numeroPersonas;

      // Call the API to create reservation
      final reserva = await _reservasService.crearReservaActividad(
        actividadId: int.parse(idActividad),
        huespedId: huespedId,
        fechaReserva: fecha,
        horaReserva: hora,
        numeroPersonas: numeroPersonas,
        montoTotal: montoTotal,
      );

      if (reserva != null) {
        // Add to local list for immediate UI update
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

  // Cancelar reserva - calls the API
  Future<bool> cancelarReserva(String idReserva) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Call the API to delete the reservation
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

  // Obtener actividad por ID
  Actividad? _obtenerActividadPorId(String id) {
    try {
      return _actividades.firstWhere((a) => a.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Public method to get actividad by ID for external use
  Actividad? obtenerActividadPorId(String id) {
    return _obtenerActividadPorId(id);
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
