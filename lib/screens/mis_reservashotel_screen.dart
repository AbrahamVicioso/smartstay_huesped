// lib/screens/mis_reservashotel_screen.dart
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/reservas_hotel_provider.dart';
import '../models/reserva_hotel.dart';
import '../theme/app_theme.dart';
import 'reserva_detalle_screen.dart';

class MisReservasHotelScreen extends StatefulWidget {
  const MisReservasHotelScreen({super.key});

  @override
  State<MisReservasHotelScreen> createState() => _MisReservasHotelScreenState();
}

class _MisReservasHotelScreenState extends State<MisReservasHotelScreen>
    with RouteAware {
  // FIX #4: Refrescar al entrar/volver a la pantalla
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
    });
  }

  // FIX #4: También refrescar al volver desde otra pantalla (ej. tras check-in)
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Se llama cada vez que la pantalla recupera el foco en el stack de navegación
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarReservas();
    });
  }

  Future<void> _cargarReservas() async {
    await context.read<ReservasHotelProvider>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        centerTitle: true,
        automaticallyImplyLeading: false,
      ),
      body: Consumer<ReservasHotelProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.reservasActivas.isEmpty) {
            return _buildEmpty(provider);
          }

          // FIX #4: Pull-to-refresh llama a cargar() correctamente
          return RefreshIndicator(
            onRefresh: _cargarReservas,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reservasActivas.length,
              itemBuilder: (context, index) => _ReservaCard(
                reserva: provider.reservasActivas[index],
                onVolver: _cargarReservas, // refresca al volver del detalle
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(ReservasHotelProvider provider) {
    // FIX #4: Pull-to-refresh también funciona en el estado vacío
    return RefreshIndicator(
      onRefresh: _cargarReservas,
      child: ListView(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.6,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text(
                    'No tienes reservas activas',
                    style: TextStyle(
                        fontSize: 16, color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final ReservaHotel reserva;
  final Future<void> Function() onVolver;

  const _ReservaCard({required this.reserva, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final color =
        reserva.tieneCheckIn ? AppColors.primary : AppColors.textSecondary;

    // FIX #2: Calcular noches restantes y forzar mínimo a 0
    final int noches = reserva.diasRestantes < 0 ? 0 : reserva.diasRestantes;
    final bool estanciaFinalizada = reserva.diasRestantes < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          // FIX #4 + #5: Al volver del detalle, refresca la lista
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservaDetalleScreen(reserva: reserva),
            ),
          );
          await onVolver();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.confirmation_number, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reserva.numeroReserva,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _StatusBadge(reserva: reserva),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateInfo(
                      label: 'Check-in',
                      date: fmt.format(reserva.fechaCheckIn),
                      icon: Icons.login,
                    ),
                  ),
                  Expanded(
                    child: _DateInfo(
                      label: 'Check-out',
                      date: fmt.format(reserva.fechaCheckOut),
                      icon: Icons.logout,
                    ),
                  ),
                ],
              ),
              if (reserva.tieneCheckIn) ...[
                const SizedBox(height: 12),
                // FIX #2: Mostrar mensaje de estancia finalizada si noches < 0
                estanciaFinalizada
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available,
                                size: 14, color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'Estancia finalizada',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w500),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(Icons.nightlight_round,
                              size: 14, color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$noches ${noches == 1 ? 'noche' : 'noches'} restantes',
                            style: const TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary),
                          ),
                        ],
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReservaHotel reserva;
  const _StatusBadge({required this.reserva});

  @override
  Widget build(BuildContext context) {
    // FIX #6: Si ya hizo check-out (diasRestantes < 0), mostrar badge distinto
    final bool finalizada =
        reserva.tieneCheckIn && reserva.diasRestantes < 0;

    final String label;
    final Color color;

    if (finalizada) {
      label = 'Check-out ✓';
      color = Colors.grey;
    } else if (reserva.tieneCheckIn) {
      label = 'Check-in ✓';
      color = AppColors.primary;
    } else {
      label = 'Pendiente';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style:
            TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  const _DateInfo(
      {required this.label, required this.date, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
            Text(date,
                style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}