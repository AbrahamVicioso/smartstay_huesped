// lib/screens/reserva_detalle_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../models/reserva_hotel.dart';
import '../services/api/habitacion_service.dart';
import '../services/reservas_hotel_provider.dart';
import '../services/nfc_hce_service.dart';
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

  Future<void> _activarNfcKey() async {
    if (_nfcActivo) {
      await NfcHceService.stopEmulation();
      setState(() => _nfcActivo = false);
      return;
    }

    // Verificar soporte
    bool supported = await NfcHceService.isSupported();
    if (!supported && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Tu dispositivo no soporta emulación NFC (HCE) o el NFC está desactivado.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _abriendoPuerta = true); // Reusamos el estado de carga visual

    try {
      // 1. Obtener credenciales del backend
      final credencial = await context
          .read<ReservasHotelProvider>()
          .getCredenciales(widget.reserva.reservaId);

      if (credencial == null || credencial['codigoPIN'] == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No se pudieron obtener las credenciales de la llave digital.'),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // 2. Mapear al formato que espera la cerradura
      final hcePayload = {
        "huespedId": widget.reserva.huespedId,
        "reservaId": widget.reserva.reservaId,
        "credencial": {
          "pin": credencial['codigoPIN'],
          "activacion": credencial['fechaActivacion'],
          "expiracion": credencial['fechaExpiracion'],
        }
      };

      // 3. Iniciar emulación
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
                  _activarNfcKey(); // Esto la desactivará según la lógica al inicio
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

  @override
  void initState() {
    super.initState();
    if (widget.reserva.tieneCheckIn) {
      _cargarHabitacion();
    }
  }

  Future<void> _cargarHabitacion() async {
    setState(() => _loadingHabitacion = true);
    try {
      _habitacion = await _habitacionService.getById(widget.reserva.habitacionId);
    } catch (e) {
      debugPrint('Error cargando habitación: $e');
    } finally {
      setState(() => _loadingHabitacion = false);
    }
  }

  Future<void> _abrirPuerta() async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Abrir Puerta'),
        content: Text(
          'Vas a abrir la puerta de la habitación ${_habitacion?.numeroHabitacion ?? widget.reserva.habitacionId}. ¿Continuar?',
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
        .abrirPuerta(widget.reserva.reservaId);

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
        backgroundColor: resultado['exitoso'] == true
            ? AppColors.primary
            : Colors.red,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMMM yyyy, HH:mm', 'es');
    final fmtDate = DateFormat('dd MMM yyyy', 'es');
    final reserva = widget.reserva;

    return Scaffold(
      appBar: AppBar(
        title: Text('Reserva #${reserva.reservaId}'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Estado badge
            Center(child: _buildEstadoBadge(reserva)),
            const SizedBox(height: 24),

            // Número de reserva
            _buildSection('Información de Reserva', [
              _buildRow(Icons.confirmation_number, 'Número', reserva.numeroReserva),
              _buildRow(Icons.people, 'Huéspedes', '${reserva.numeroHuespedes} adultos, ${reserva.numeroNinos} niños'),
              if (reserva.observaciones != null)
                _buildRow(Icons.notes, 'Notas', reserva.observaciones!),
            ]),

            const SizedBox(height: 20),

            // Fechas
            _buildSection('Fechas', [
              _buildRow(Icons.login, 'Check-in previsto', fmtDate.format(reserva.fechaCheckIn)),
              _buildRow(Icons.logout, 'Check-out previsto', fmtDate.format(reserva.fechaCheckOut)),
              if (reserva.checkInRealizado != null)
                _buildRow(Icons.check_circle, 'Check-in realizado',
                    fmt.format(reserva.checkInRealizado!.toLocal())),
            ]),

            const SizedBox(height: 20),

            // Habitación — solo si hay check-in
            if (reserva.tieneCheckIn) ...[
              _buildSection('Tu Habitación', []),
              const SizedBox(height: 8),
              _buildHabitacionCard(),
              const SizedBox(height: 20),
            ] else ...[
              // Sin check-in
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.orange.withOpacity(0.3)),
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

      // Botón abrir puerta — solo si hay check-in y puede desbloquear
      bottomNavigationBar: reserva.tieneCheckIn && reserva.puedeDesbloquearCerradura
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
                        icon: const Icon(Icons.nfc),
                        label: const Text('Llave NFC'),
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.primary),
                          foregroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
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
                        onPressed: _abriendoPuerta ? null : _abrirPuerta,
                        icon: _abriendoPuerta
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white),
                              )
                            : const Icon(Icons.lock_open),
                        label: Text(_abriendoPuerta ? 'Abriendo...' : 'Abrir Puerta'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          textStyle: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w600),
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

  Widget _buildEstadoBadge(ReservaHotel reserva) {
    final label = reserva.tieneCheckIn ? 'Check-in Realizado ✓' : 'Esperando Check-in';
    final color = reserva.tieneCheckIn ? AppColors.primary : Colors.orange;

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

    final numero = _habitacion?.numeroHabitacion ?? '${widget.reserva.habitacionId}';
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
                      color: Colors.white.withOpacity(0.8), fontSize: 14),
                ),
                if (piso != null)
                  Text(
                    'Piso $piso',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12),
                  ),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
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
                        fontSize: 12, color: AppColors.textSecondary)),
                const SizedBox(height: 2),
                Text(value,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}