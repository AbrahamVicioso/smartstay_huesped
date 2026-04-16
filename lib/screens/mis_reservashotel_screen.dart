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

class _MisReservasHotelScreenState extends State<MisReservasHotelScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReservasHotelProvider>().cargar();
    });
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
            return _buildEmpty();
          }

          return RefreshIndicator(
            onRefresh: () => provider.cargar(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: provider.reservasActivas.length,
              itemBuilder: (context, index) =>
                  _ReservaCard(reserva: provider.reservasActivas[index]),
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hotel_outlined, size: 80,
              color: AppColors.textSecondary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text('No tienes reservas activas',
              style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final ReservaHotel reserva;
  const _ReservaCard({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final color = reserva.tieneCheckIn ? AppColors.primary : AppColors.textSecondary;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ReservaDetalleScreen(reserva: reserva),
          ),
        ),
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
                Row(
                  children: [
                    const Icon(Icons.nightlight_round,
                        size: 14, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${reserva.diasRestantes} noches restantes',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.textSecondary),
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
    final label = reserva.tieneCheckIn ? 'Check-in ✓' : 'Pendiente';
    final color = reserva.tieneCheckIn ? AppColors.primary : Colors.orange;

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
            fontSize: 11, color: color, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  const _DateInfo({required this.label, required this.date, required this.icon});

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