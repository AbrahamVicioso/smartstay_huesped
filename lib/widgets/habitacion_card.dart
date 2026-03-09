import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/api/habitacion.dart';
import '../theme/app_theme.dart';
import 'apertura_opciones_sheet.dart';

class HabitacionCard extends StatelessWidget {
  final dynamic habitacionData;
  final bool showReservaButton;
  final VoidCallback? onVerReserva;

  const HabitacionCard({
    super.key,
    required this.habitacionData,
    this.showReservaButton = false,
    this.onVerReserva,
  });

  String get numeroHabitacion {
    if (habitacionData is Habitacion) {
      return habitacionData.numeroHabitacion;
    } else if (habitacionData is Reserva) {
      return habitacionData.numeroHabitacion;
    }
    return '-';
  }

  String get tipoHabitacion {
    if (habitacionData is Habitacion) {
      return habitacionData.tipoHabitacion;
    } else if (habitacionData is Reserva) {
      return habitacionData.tipoHabitacion;
    }
    return 'Habitación';
  }

  String get estado {
    if (habitacionData is Habitacion) {
      return habitacionData.tieneReservaActiva ? 'Activa' : habitacionData.estado;
    } else if (habitacionData is Reserva) {
      return habitacionData.estaActiva ? 'Activa' : habitacionData.estado;
    }
    return 'Desconocido';
  }

  bool get estaActiva {
    if (habitacionData is Habitacion) {
      return habitacionData.tieneReservaActiva;
    } else if (habitacionData is Reserva) {
      return habitacionData.estaActiva;
    }
    return false;
  }

  String get pinAcceso {
    if (habitacionData is Habitacion) {
      return habitacionData.pinAcceso ?? '------';
    } else if (habitacionData is Reserva) {
      return habitacionData.pinAcceso;
    }
    return '------';
  }

  int get diasRestantes {
    if (habitacionData is Habitacion) {
      return habitacionData.diasRestantes;
    } else if (habitacionData is Reserva) {
      return habitacionData.diasRestantes;
    }
    return 0;
  }

  DateTime? get fechaCheckOut {
    if (habitacionData is Habitacion) {
      return habitacionData.fechaCheckOut;
    } else if (habitacionData is Reserva) {
      return habitacionData.fechaSalida;
    }
    return null;
  }

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
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.hotel,
                    color: AppTheme.primaryColor,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitación $numeroHabitacion',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        tipoHabitacion,
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
                          color: estaActiva
                              ? Colors.green.withValues(alpha: 0.1)
                              : Colors.grey.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          estaActiva ? 'Activa' : estado,
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: estaActiva
                                ? Colors.green.shade700
                                : Colors.grey.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
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
                ),
                if (showReservaButton && onVerReserva != null) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onVerReserva,
                      icon: const Icon(Icons.description, size: 20),
                      label: const Text('Ver Reserva'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _InfoChip(
                  icon: Icons.pin,
                  label: 'PIN',
                  value: pinAcceso,
                ),
                _InfoChip(
                  icon: Icons.nightlight_round,
                  label: 'Noches',
                  value: '$diasRestantes',
                ),
                _InfoChip(
                  icon: Icons.event,
                  label: 'Check-out',
                  value: _formatDate(fechaCheckOut),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '-';
    return '${date.day}/${date.month}';
  }

  void _mostrarOpcionesApertura(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => AperturaOpcionesSheet(habitacionData: habitacionData),
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
