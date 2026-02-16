import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/api/reserva_actividad.dart';
import '../services/api/reservas_service.dart';
import '../services/api/huespedes_service.dart';
import '../services/secure_storage_service.dart';


class ReservasProvider with ChangeNotifier {
  List<ReservaActividadApi> _misReservas = [];

  bool _isLoading = false;
  String? _errorMessage;

  final SecureStorageService _storage = SecureStorageService();
  final ReservasService _reservasService = ReservasService();
  final HuespedesService _huespedesService = HuespedesService();

  List<ReservaActividadApi> get misReservas => _misReservas;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> cargarMisReservas() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // 1. Obtener token
      final accessToken = await _storage.getAccessToken();
      if (accessToken == null) {
        throw Exception('No hay sesion activa');
      }

      // 2. Decodificar JWT para obtener el GUID del usuario
      final decodedToken = JwtDecoder.decode(accessToken);
      final userId = decodedToken[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
      ] as String?;

      debugPrint('[ReservasProvider] UserId from JWT: $userId');

      if (userId == null) {
        throw Exception('No se pudo obtener el ID del usuario');
      }

      // 3. Buscar HuespedId usando GET /Huesped/user/{usuarioId}
      final huespedId = await _huespedesService.getHuespedIdByUsuarioId(userId);
      debugPrint('[ReservasProvider] HuespedId: $huespedId');

      if (huespedId == null) {
        _misReservas = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // 4. Obtener reservas de actividades filtradas por huespedId
      _misReservas = await _reservasService.getReservasActividadesByHuespedId(huespedId);
      debugPrint('[ReservasProvider] Reservas cargadas: ${_misReservas.length}');

    } catch (e) {
      _errorMessage = e.toString();
      debugPrint('[ReservasProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Reservas activas
  List<ReservaActividadApi> get reservasActivas => _misReservas.where((r) {
    final estado = r.estado.toLowerCase();
    return estado == 'confirmada' ||
        estado == 'checkin' ||
        estado == 'pendiente';
  }).toList();

  // Reservas pasadas
  List<ReservaActividadApi> get reservasPasadas => _misReservas.where((r) {
    final estado = r.estado.toLowerCase();
    return estado == 'checkout' ||
        estado == 'cancelada' ||
        estado == 'completada';
  }).toList();
}
