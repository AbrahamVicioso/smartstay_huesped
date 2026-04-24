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
  State<MisReservasHotelScreen> createState() =>
      _MisReservasHotelScreenState();
}

class _MisReservasHotelScreenState extends State<MisReservasHotelScreen>
    with RouteAware {

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _cargarReservas();
    });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _cargarReservas();
    });
  }

  Future<void> _cargarReservas() async {
    await context.read<ReservasHotelProvider>().cargar();
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Mis Reservas'),
          centerTitle: true,
          automaticallyImplyLeading: false,
          actions: [
            Consumer<ReservasHotelProvider>(
              builder: (context, provider, _) => IconButton(
                icon: provider.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: provider.isLoading ? null : _cargarReservas,
                tooltip: 'Refrescar',
              ),
            ),
          ],
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Activas'),
              Tab(text: 'Historial'),
            ],
          ),
        ),
        body: Consumer<ReservasHotelProvider>(
          builder: (context, provider, _) {
            if (provider.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }

            return TabBarView(
              children: [
                _buildLista(provider.reservasActivas, esHistorial: false),
                _buildLista(provider.historial, esHistorial: true),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLista(
    List<ReservaHotel> lista, {
    required bool esHistorial,
  }) {
    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarReservas,
        child: ListView(
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.5,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      esHistorial
                          ? Icons.history
                          : Icons.hotel_outlined,
                      size: 80,
                      color: AppColors.textSecondary.withOpacity(0.4),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      esHistorial
                          ? 'Sin reservas en historial'
                          : 'No tienes reservas activas',
                      style: const TextStyle(
                        fontSize: 16,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargarReservas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (context, index) => _ReservaCard(
          reserva: lista[index],
          onVolver: _cargarReservas,
        ),
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

    final int noches = reserva.diasRestantes < 0 ? 0 : reserva.diasRestantes;
    final bool estanciaFinalizada = reserva.diasRestantes < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
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
                                size: 14,
                                color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'Estancia finalizada',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(Icons.nightlight_round,
                              size: 14,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$noches ${noches == 1 ? 'noche' : 'noches'} restantes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
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
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;

  const _DateInfo({
    required this.label,
    required this.date,
    required this.icon,
  });

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
                    fontSize: 11,
                    color: AppColors.textSecondary)),
            Text(date,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}