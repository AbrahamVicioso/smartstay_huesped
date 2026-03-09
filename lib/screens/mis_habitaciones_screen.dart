import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../models/api/habitacion.dart';
import '../models/api/reserva_api.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/habitacion_card.dart';
import 'habitacion_detalle_screen.dart';

class MisHabitacionesScreen extends StatelessWidget {
  const MisHabitacionesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Habitaciones'),
        centerTitle: true,
      ),
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
                      builder: (context) => HabitacionDetalleScreen(
                        habitacion: habitacion,
                      ),
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
        ),
      ),
    );
  }
}
