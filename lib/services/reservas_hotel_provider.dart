// lib/services/reservas_hotel_provider.dart
import 'package:flutter/foundation.dart';
import '../models/reserva_hotel.dart';
import 'api/reservas_hotel_service.dart';
import 'secure_storage_service.dart';
import 'package:jwt_decoder/jwt_decoder.dart';

class ReservasHotelProvider with ChangeNotifier {
  final ReservasHotelService _service = ReservasHotelService();
  final SecureStorageService _storage = SecureStorageService();

  List<ReservaHotel> _reservas = [];
  bool _isLoading = false;
  String? _error;

  List<ReservaHotel> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // Solo reservas sin checkout
  List<ReservaHotel> get reservasActivas =>
      _reservas.where((r) => !r.tieneCheckOut).toList();

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('Sin sesión');

      final decoded = JwtDecoder.decode(token);
      final userId = decoded[
        'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'
      ] as String?;

      if (userId == null) throw Exception('No se pudo obtener userId');

      _reservas = await _service.getReservasByUserId(userId, token: token);
      debugPrint('[ReservasHotelProvider] Reservas cargadas: ${_reservas.length}');
    } catch (e) {
      _error = e.toString();
      debugPrint('[ReservasHotelProvider] Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> abrirPuerta(int reservaId, {String? pin}) async {
    final token = await _storage.getAccessToken();
    return _service.abrirPuerta(reservaId, pin: pin, token: token);
  }
}