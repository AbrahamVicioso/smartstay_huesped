// lib/services/reservas_hotel_provider.dart
import 'package:flutter/foundation.dart';
import '../models/reserva_hotel.dart';
import 'api/reservas_service.dart';
import 'api/secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ReservasHotelProvider with ChangeNotifier {
  final ReservasService _service = ReservasService();
  final SecureStorageService _storage = SecureStorageService();

  List<ReservaHotel> _reservas = [];
  bool _isLoading = false;
  String? _error;

  List<ReservaHotel> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  List<ReservaHotel> get reservasActivas =>
      _reservas.where((r) => !r.tieneCheckOut).toList();

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.getAccessToken();
      if (token == null) {
        throw Exception('Sin sesión activa');
      }

      final decoded = JwtDecoder.decode(token);
      final userId = decoded['http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] as String?;

      if (userId == null) {
        throw Exception('No se pudo obtener el ID de usuario');
      }

      debugPrint('[ReservasHotelProvider] Cargando reservas para usuario: $userId');

      final reservasApi = await _service.getReservasByUserId(userId);
      
      debugPrint('[ReservasHotelProvider] Respuesta de API: ${reservasApi.length} reservas');

      if (reservasApi.isEmpty) {
        _reservas = [];
        debugPrint('[ReservasHotelProvider] No hay reservas para este usuario');
      } else {
        _reservas = reservasApi
            .map((api) => ReservaHotel.fromJson(api.toJson()))
            .toList();
        debugPrint('[ReservasHotelProvider] Reservas cargadas exitosamente: ${_reservas.length}');
      }
      
      _error = null;
    } catch (e) {
      _error = 'Error al cargar las reservas';
      _reservas = [];
      debugPrint('[ReservasHotelProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> abrirPuerta(int reservaId, {String? pin}) async {
    return _service.abrirPuerta(reservaId, pin: pin);
  }

  Future<Map<String, dynamic>?> getCredenciales(int reservaId) async {
    return _service.getCredenciales(reservaId);
  }
}