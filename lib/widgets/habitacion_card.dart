import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../theme/app_theme.dart';
import 'apertura_opciones_sheet.dart';

class HabitacionCard extends StatelessWidget {
  final Reserva reserva;

  const HabitacionCard({
    super.key,
    required this.reserva,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                // Icono de habitación
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hotel,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),

                // Información de habitación
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitación ${reserva.numeroHabitacion}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reserva.tipoHabitacion,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: reserva.estaActiva
                              ? Colors.green.withOpacity(0.1)
                              : Colors.grey.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          reserva.estaActiva ? 'Activa' : reserva.estado,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: reserva.estaActiva
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botón de abrir
                ElevatedButton.icon(
                  onPressed: () {
                    _mostrarOpcionesApertura(context);
                  },
                  icon: const Icon(Icons.lock_open, size: 20),
                  label: const Text('Abrir'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                ),
              ],
            ),

            const Divider(height: 24),

            // Información adicional
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.pin,
                  label: 'PIN',
                  value: reserva.pinAcceso,
                ),
                _InfoChip(
                  icon: Icons.nightlight_round,
                  label: 'Noches',
                  value: '${reserva.diasRestantes}',
                ),
                _InfoChip(
                  icon: Icons.event,
                  label: 'Check-out',
                  value: '${reserva.fechaSalida.day}/${reserva.fechaSalida.month}',
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarOpcionesApertura(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AperturaOpcionesSheet(reserva: reserva),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: AppTheme.primaryColor),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: Theme.of(context).textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
