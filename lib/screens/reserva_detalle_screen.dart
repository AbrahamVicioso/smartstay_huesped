// lib/screens/reserva_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reserva_hotel.dart';
import '../services/api/habitacion_service.dart';
import '../services/reservas_hotel_provider.dart';
import '../services/api/nfc_hce_service.dart';
import '../theme/app_theme.dart';

class ReservaDetalleScreen extends StatefulWidget {
  final ReservaHotel reserva;
  const ReservaDetalleScreen({super.key, required this.reserva});

  @override
  State<ReservaDetalleScreen> createState() => _ReservaDetalleScreenState();
}

class _ReservaDetalleScreenState extends State<ReservaDetalleScreen> {
  final HabitacionService _habitacionService = HabitacionService();
  dynamic _habitacion;
  bool _loadingHabitacion = false;
  bool _abriendoPuerta = false;
  bool _nfcActivo = false;

  // FIX #5: Mantener una copia local de la reserva que se actualiza
  late ReservaHotel _reserva;

  @override
  void initState() {
    super.initState();
    _reserva = widget.reserva;
    if (_reserva.tieneCheckIn) {
      _cargarHabitacion();
    }
  }

  // FIX #5: Refresca los datos de la reserva desde el provider
  Future<void> _refrescarReserva() async {
    final provider = context.read<ReservasHotelProvider>();
    await provider.cargar();

    if (!mounted) return;

    // Buscar la reserva actualizada en el provider
    final reservaActualizada = provider.reservas.firstWhere(
      (r) => r.reservaId == _reserva.reservaId,
      orElse: () => _reserva,
    );

    setState(() {
      _reserva = reservaActualizada;
    });

    // Si ahora tiene check-in y antes no tenía habitación cargada, cargarla
    if (_reserva.tieneCheckIn && _habitacion == null) {
      await _cargarHabitacion();
    }
  }

  Future<void> _activarNfcKey() async {
    if (_nfcActivo) {
      await NfcHceService.stopEmulation();
      setState(() => _nfcActivo = false);
      return;
    }

    bool supported = await NfcHceService.isSupported();
    if (!supported && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
              'Tu dispositivo no soporta emulación NFC (HCE) o el NFC está desactivado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _abriendoPuerta = true);

    try {
      final credencial = await context
          .read<ReservasHotelProvider>()
          .getCredenciales(_reserva.reservaId);

      if (credencial == null || credencial['codigoPIN'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                  'No se pudieron obtener las credenciales de la llave digital.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      final hcePayload = {
        "huespedId": _reserva.huespedId,
        "reservaId": _reserva.reservaId,
        "credencial": {
          "pin": credencial['codigoPIN'],
          "activacion": credencial['fechaActivacion'],
          "expiracion": credencial['fechaExpiracion'],
        }
      };

      bool success = await NfcHceService.startEmulation(hcePayload);

      if (success) {
        setState(() => _nfcActivo = true);
        if (mounted) {
          _mostrarModalLlaveActiva();
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Error al iniciar la emulación NFC.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint('Error en _activarNfcKey: $e');
    } finally {
      if (mounted) {
        setState(() => _abriendoPuerta = false);
      }
    }
  }

  void _mostrarModalLlaveActiva() {
    showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.nfc, size: 64, color: AppColors.primary),
            const SizedBox(height: 16),
            const Text(
              'Llave Digital Activa',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Acerque la parte trasera de su teléfono al lector de la cerradura.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  _activarNfcKey();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade400,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Finalizar / Desactivar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _cargarHabitacion() async {
    setState(() => _loadingHabitacion = true);
    try {
      _habitacion =
          await _habitacionService.getById(_reserva.habitacionId);
    } catch (e) {
      debugPrint('Error cargando habitación: $e');
    } finally {
      if (mounted) setState(() => _loadingHabitacion = false);
    }
  }

  Future<void> _abrirPuerta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir Puerta'),
        content: Text(
          'Vas a abrir la puerta de la habitación '
          '${_habitacion?.numeroHabitacion ?? _reserva.habitacionId}. ¿Continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Abrir'),
          ),
        ],
      ),
    );

    if (confirmar != true || !mounted) return;

    setState(() => _abriendoPuerta = true);

    final resultado = await context
        .read<ReservasHotelProvider>()
        .abrirPuerta(_reserva.reservaId);

    if (!mounted) return;
    setState(() => _abriendoPuerta = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              resultado['exitoso'] == true
                  ? Icons.check_circle
                  : Icons.error,
              color: Colors.white,
            ),
            const SizedBox(width: 8),
            Expanded(child: Text(resultado['mensaje'] ?? '')),
          ],
        ),
        backgroundColor:
            resultado['exitoso'] == true ? AppColors.primary : Colors.red,
      ),
    );
  }

  // FIX #6: Verificar si la estancia ya terminó (check-out completado)
  bool get _estanciaFinalizada =>
      _reserva.tieneCheckIn && _reserva.diasRestantes < 0;

  // FIX #5 + #6: El botón sólo aparece si tiene check-in activo
  // Y la estancia NO está finalizada (check-out no ocurrido)
  bool get _puedeAbrirPuerta =>
      _reserva.tieneCheckIn &&
      _reserva.puedeDesbloquearCerradura &&
      !_estanciaFinalizada;

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMMM yyyy, HH:mm', 'es');
    final fmtDate = DateFormat('dd MMM yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        // FIX #1: Título estático en lugar de mostrar el ID con #
        title: const Text('Detalle de la Estancia'),
        centerTitle: true,
        // FIX #5: Botón de refresco manual en la AppBar
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _refrescarReserva,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado badge
            Center(child: _buildEstadoBadge(_reserva)),
            const SizedBox(height: 24),

            // Número de reserva
            _buildSection('Información de Reserva', [
              _buildRow(Icons.confirmation_number, 'Número',
                  _reserva.numeroReserva),
              _buildRow(Icons.people, 'Huéspedes',
                  '${_reserva.numeroHuespedes} adultos, ${_reserva.numeroNinos} niños'),
              if (_reserva.observaciones != null)
                _buildRow(
                    Icons.notes, 'Notas', _reserva.observaciones!),
            ]),

            const SizedBox(height: 20),

            // Fechas
            _buildSection('Fechas', [
              _buildRow(Icons.login, 'Check-in previsto',
                  fmtDate.format(_reserva.fechaCheckIn)),
              _buildRow(Icons.logout, 'Check-out previsto',
                  fmtDate.format(_reserva.fechaCheckOut)),
              if (_reserva.checkInRealizado != null)
                _buildRow(
                  Icons.check_circle,
                  'Check-in realizado',
                  fmt.format(_reserva.checkInRealizado!.toLocal()),
                ),
            ]),

            const SizedBox(height: 20),

            // Habitación — solo si hay check-in
            if (_reserva.tieneCheckIn) ...[
              _buildSection('Tu Habitación', []),
              const SizedBox(height: 8),
              _buildHabitacionCard(),
              const SizedBox(height: 20),

              // FIX #2 + #6: Banner informativo según estado de la estancia
              if (_estanciaFinalizada)
                _buildBannerCheckout()
              else
                _buildNochesRestantes(),

              const SizedBox(height: 20),
            ] else ...[
              // Sin check-in
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.orange.withOpacity(0.3)),
                ),
                child: const Row(
                  children: [
                    Icon(Icons.info_outline, color: Colors.orange),
                    SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Tu habitación estará disponible después de que el recepcionista realice el check-in.',
                        style: TextStyle(color: Colors.orange),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ],
        ),
      ),

      // FIX #5 + #6: Botón de apertura controlado por _puedeAbrirPuerta
      bottomNavigationBar: _puedeAbrirPuerta
          ? Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
              decoration: BoxDecoration(
                color: AppColors.background,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 54,
                      child: OutlinedButton.icon(
                        onPressed: _abriendoPuerta ? null : _activarNfcKey,
                        icon: Icon(
                            _nfcActivo ? Icons.nfc : Icons.nfc,
                            color: _nfcActivo
                                ? Colors.green
                                : AppColors.primary),
                        label: Text(
                          _nfcActivo ? 'NFC Activo' : 'Llave NFC',
                          style: TextStyle(
                              color: _nfcActivo
                                  ? Colors.green
                                  : AppColors.primary),
                        ),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                              color: _nfcActivo
                                  ? Colors.green
                                  : AppColors.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 1,
                    child: SizedBox(
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed:
                            _abriendoPuerta ? null : _abrirPuerta,
                        icon: _abriendoPuerta
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white),
                              )
                            : const Icon(Icons.lock_open),
                        label: Text(
                            _abriendoPuerta ? 'Abriendo...' : 'Abrir Puerta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : null,
    );
  }

  // FIX #6: Banner para estancia finalizada
  Widget _buildBannerCheckout() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.3)),
      ),
      child: const Row(
        children: [
          Icon(Icons.event_available, color: Colors.grey),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Esta estancia ha finalizado. El acceso a la habitación ya no está disponible.',
              style: TextStyle(color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  // FIX #2: Noches restantes — nunca negativo
  Widget _buildNochesRestantes() {
    final int noches =
        _reserva.diasRestantes < 0 ? 0 : _reserva.diasRestantes;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          const Icon(Icons.nightlight_round,
              color: AppColors.primary, size: 20),
          const SizedBox(width: 10),
          Text(
            noches == 0
                ? 'Última noche de estancia'
                : '$noches ${noches == 1 ? 'noche restante' : 'noches restantes'}',
            style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.primary),
          ),
        ],
      ),
    );
  }

  Widget _buildEstadoBadge(ReservaHotel reserva) {
    // FIX #6: Badge diferenciado para check-out
    final String label;
    final Color color;

    if (_estanciaFinalizada) {
      label = 'Estancia Finalizada';
      color = Colors.grey;
    } else if (reserva.tieneCheckIn) {
      label = 'Check-in Realizado ✓';
      color = AppColors.primary;
    } else {
      label = 'Esperando Check-in';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
            color: color, fontWeight: FontWeight.w600, fontSize: 14),
      ),
    );
  }

  Widget _buildHabitacionCard() {
    if (_loadingHabitacion) {
      return const Center(child: CircularProgressIndicator());
    }

    final numero =
        _habitacion?.numeroHabitacion ?? '${_reserva.habitacionId}';
    final tipo = _habitacion?.tipoHabitacion ?? 'Habitación';
    final piso = _habitacion?.piso;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.hotel, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Habitación $numero',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  tipo,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 14),
                ),
                if (piso != null)
                  Text(
                    'Piso $piso',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7),
                        fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios,
              color: Colors.white54, size: 16),
        ],
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary),
        ),
        const SizedBox(height: 12),
        if (children.isNotEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.backgroundSecondary,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(children: children),
          ),
      ],
    );
  }

  Widget _buildRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}