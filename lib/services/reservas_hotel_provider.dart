
import 'package:flutter/foundation.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import '../models/reserva_hotel.dart';
import 'api/reservas_service.dart';
import 'api/huespedes_service.dart';
import 'api/secure_storage_service.dart';

class ReservasHotelProvider with ChangeNotifier {
  final ReservasService _reservasService = ReservasService();
  final HuespedesService _huespedesService = HuespedesService();
  final SecureStorageService _storage = SecureStorageService();

  List<ReservaHotel> _reservas = [];
  bool _isLoading = false;
  String? _error;
   bool _cargado = false;

  List<ReservaHotel> get reservas => _reservas;
  bool get isLoading => _isLoading;
  String? get error => _error;
   bool get cargado => _cargado;
  
  List<ReservaHotel> get reservasActivas =>
      _reservas.where((r) => r.estadoReservaId == 1 || r.estadoReservaId == 2).toList();

  
  List<ReservaHotel> get historial =>
      _reservas.where((r) => r.estadoReservaId == 3 || r.estadoReservaId == 4).toList();

  Future<void> cargar() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final token = await _storage.getAccessToken();
      if (token == null) throw Exception('Sin sesión activa');

      final decoded = JwtDecoder.decode(token);
      final userId = decoded[
           'http://schemas.xmlsoap.org/ws/2005/05/identity/claims/nameidentifier'] as String?;
      if (userId == null) throw Exception('No se pudo obtener el ID de usuario');


      
      final huesped = await _huespedesService.getHuespedByUsuarioId(userId);
      if (huesped == null || huesped.huespedId == null) {
        debugPrint('[ReservasHotelProvider] No se encontró huésped para userId=$userId');
        _reservas = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      final huespedId = huesped.huespedId!;
      debugPrint('[ReservasHotelProvider] Cargando reservas para huespedId=$huespedId');

      
      final reservasApi = await _reservasService.getByHuespedId(huespedId);

      debugPrint('[ReservasHotelProvider] Reservas recibidas: ${reservasApi.length}');
      for (final r in reservasApi) {
        debugPrint('  API → id=${r.reservaId} estado=${r.estado} estadoId=??? checkOut=${r.checkOutRealizado}');
      }

      _reservas = reservasApi
          .map((api) => ReservaHotel.fromJson(api.toJson()))
          .toList();

      for (final r in _reservas) {
        debugPrint('  MODEL → id=${r.reservaId} estadoReservaId=${r.estadoReservaId} esHistorial=${r.esHistorial}');
      }

      debugPrint('[ReservasHotelProvider] Activas: ${reservasActivas.length}, Historial: ${historial.length}');
      _error = null;
    } catch (e) {
      _error = 'Error al cargar las reservas';
      _reservas = [];
      debugPrint('[ReservasHotelProvider] Error: $e');
    } finally {
      _isLoading = false;
      _cargado = true; 
      notifyListeners();
    }
  }

  Future<Map<String, dynamic>> abrirPuerta(int reservaId, {String? pin}) async {
    return _reservasService.abrirPuerta(reservaId, pin: pin);
  }

  Future<Map<String, dynamic>?> getCredenciales(int reservaId) async {
    return _reservasService.getCredenciales(reservaId);
  }

  Future<void> recargar() async {
  _cargado = false;
  await cargar();
}
}