// lib/services/actividades_provider.dart
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/actividad.dart';
import '../models/api/actividad_recreativa.dart';
import '../models/api/reserva_actividad.dart';
import 'api/actividades_recreativas_service.dart';
import 'api/reservas_actividades_service.dart'; 
import 'api/huespedes_service.dart';
import 'api/secure_storage_service.dart';

class ActividadesProvider with ChangeNotifier {
  List<Actividad> _actividades = [];
  final List<ReservaActividad> _misReservas = [];
  bool _isLoading = false;
  String? _errorMessage;

  final _actividadesService = ActividadesRecreativasService();
  final _reservasService = ReservasActividadesService(); 
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
      debugPrint('[ActividadesProvider] Actividades recibidas de API: ${actividadesApi.length}');

      // Convert API model to local Actividad model con manejo de errores
      _actividades = [];
      for (var a in actividadesApi) {
        try {
          if (a.estaActiva) {
            final actividad = _convertirActividadRecreativa(a);
            _actividades.add(actividad);
          }
        } catch (e) {
          debugPrint('[ActividadesProvider] Error convirtiendo actividad ${a.actividadId}: $e');
          // Continúa con la siguiente actividad en lugar de fallar completamente
        }
      }

      debugPrint('[ActividadesProvider] Actividades activas cargadas: ${_actividades.length}');

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      debugPrint('[ActividadesProvider] Error cargando actividades: $e');
      _errorMessage = 'Error al cargar actividades';
      _actividades = []; // Asegurarse de que la lista está vacía en caso de error
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Convert ActividadRecreativa (API model) to Actividad (local model)
  Actividad _convertirActividadRecreativa(ActividadRecreativa api) {
    return Actividad(
      id: api.actividadId.toString(),
      nombre: api.nombreActividad ?? 'Sin nombre',
      descripcion: api.descripcion ?? 'Sin descripción',
      icono: _getIconForCategory(api.categoria ?? ''),
      categoria: (api.categoria ?? 'general').toLowerCase(),
      horarioApertura: _formatTimeSpan(api.horaApertura ?? '00:00:00'),
      horarioCierre: _formatTimeSpan(api.horaCierre ?? '23:59:59'),
      capacidadMaxima: api.capacidadMaxima ?? 0,
      requiereReserva: api.requiereReserva ?? false,
      precio: (api.precioPorPersona != null && api.precioPorPersona! > 0) 
          ? api.precioPorPersona 
          : null,
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
      return '00:00';
    }
  }

  /// Get HuespedId from userId
  Future<int?> _getHuespedId() async {
    try {
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        throw Exception('No hay sesión activa');
      }

      final decodedToken = JwtDecoder.decode(accessToken);
      final userId = decodedToken[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
      ] as String?;

      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      final huespedId = await _huespedesService.getHuespedIdByUsuarioId(userId);
      return huespedId;
    } catch (e) {
      debugPrint('[ActividadesProvider] Error getting huespedId: $e');
      return null;
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

  // Cancelar reserva
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