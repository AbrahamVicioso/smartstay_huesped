import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habitacion_card.dart';
import 'habitacion_detalle_screen.dart';

class MisHabitacionesScreen extends StatelessWidget {
  const MisHabitacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mis Habitaciones'), centerTitle: true),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, child) {
          final habitaciones = authProvider.habitacionesDetalladas;

          if (habitaciones.isEmpty) {
            return _buildEmptyState(context);
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: habitaciones.length,
            itemBuilder: (context, index) {
              final habitacion = habitaciones[index];
              return HabitacionCard(
                habitacionData: habitacion,
                showReservaButton: true,
                onVerReserva: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          HabitacionDetalleScreen(habitacion: habitacion),
                    ),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Consumer<AuthProvider>(
              builder: (context, authProvider, child) {
                final reserva = authProvider.reservaActual;
                if (reserva != null) {
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.event_note,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'Información de tu reserva',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      _buildReservaInfoRow(context, 'Número de reserva', reserva.numeroReserva),
                      _buildReservaInfoRow(context, 'Estado', reserva.estado),
                      _buildReservaInfoRow(context, 'Fecha de entrada', _formatDate(reserva.fechaEntrada)),
                      _buildReservaInfoRow(context, 'Fecha de salida', _formatDate(reserva.fechaSalida)),
                      _buildReservaInfoRow(context, 'Número de huéspedes', '${reserva.numeroHuespedes}'),
                      _buildReservaInfoRow(context, 'Número de niños', '${reserva.numeroNinos}'),
                      const SizedBox(height: 24),
                      Text(
                        'Las habitaciones estarán disponibles después de realizar el check-in en la web administrativa',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                } else {
                  
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.hotel_outlined,
                        size: 80,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 24),
                      Text(
                        'No tienes habitaciones asignadas',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Las habitaciones aparecerán automáticamente cuando hagas una reserva',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textPrimary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
