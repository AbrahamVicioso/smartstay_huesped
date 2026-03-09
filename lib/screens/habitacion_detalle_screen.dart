import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/api/habitacion.dart';
import '../theme/app_theme.dart';
import '../widgets/apertura_opciones_sheet.dart';

class HabitacionDetalleScreen extends StatelessWidget {
  final Habitacion? habitacion;

  const HabitacionDetalleScreen({super.key, this.habitacion});

  Habitacion get _hab => habitacion!;

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMMM yyyy', 'es');

    return Scaffold(
      appBar: AppBar(
        title: Text(
          habitacion == null ? 'Habitación' : 'Habitación ${_hab.numeroHabitacion}',
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoCard(context),
            const SizedBox(height: 24),
            if (habitacion != null && _hab.reservaId != null) ...[
              Text(
                'Detalles de la Reserva',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 16),
              _buildReservaCard(context, dateFormat),
              const SizedBox(height: 24),
            ],
            _buildStatusCard(context),
            const SizedBox(height: 24),
            _buildActionsCard(context),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.hotel, size: 48, color: AppTheme.primaryColor),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitación ${_hab.numeroHabitacion}',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _hab.tipoHabitacion,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 32),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildInfoItem(context, Icons.layers, 'Piso', '${_hab.piso}'),
                _buildInfoItem(context, Icons.people, 'Capacidad', '${_hab.capacidadMaxima} personas'),
                _buildInfoItem(context, Icons.attach_money, 'Precio/Noche', '\$${_hab.precioPorNoche.toStringAsFixed(0)}'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoItem(BuildContext context, IconData icon, String label, String value) {
    return Column(
      children: [
        Icon(icon, color: AppTheme.primaryColor, size: 28),
        const SizedBox(height: 8),
        Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildReservaCard(BuildContext context, DateFormat dateFormat) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildReservaRow(context, Icons.confirmation_number, 'Número de Reserva', '#${_hab.reservaId}'),
            const Divider(height: 24),
            _buildReservaRow(
              context, Icons.login, 'Check-in',
              _hab.fechaCheckIn != null ? dateFormat.format(_hab.fechaCheckIn!) : 'No disponible',
            ),
            const Divider(height: 24),
            _buildReservaRow(
              context, Icons.logout, 'Check-out',
              _hab.fechaCheckOut != null ? dateFormat.format(_hab.fechaCheckOut!) : 'No disponible',
            ),
            const Divider(height: 24),
            _buildReservaRow(context, Icons.nightlight_round, 'Noches Restantes', '${_hab.diasRestantes}'),
            const Divider(height: 24),
            _buildReservaRow(context, Icons.pin, 'PIN de Acceso', _hab.pinAcceso ?? '------'),
          ],
        ),
      ),
    );
  }

  Widget _buildReservaRow(BuildContext context, IconData icon, String label, String value) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppTheme.goldColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: AppTheme.goldColor, size: 24),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary)),
              Text(value, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStatusCard(BuildContext context) {
    final isActive = habitacion != null && _hab.tieneReservaActiva;
    return Card(
      color: isActive ? Colors.green.shade50 : Colors.grey.shade50,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isActive ? Colors.green.withValues(alpha: 0.2) : Colors.grey.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(isActive ? Icons.check_circle : Icons.schedule, color: isActive ? Colors.green : Colors.grey, size: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isActive ? 'Reserva Activa' : 'Reserva Inactiva',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isActive ? Colors.green.shade700 : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    isActive ? 'Tu reserva está confirmada y vigente' : 'Tu reserva aún no está activa o ya expiró',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionsCard(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        ElevatedButton.icon(
          onPressed: habitacion != null
              ? () => showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: Colors.transparent,
                    builder: (context) => AperturaOpcionesSheet(habitacionData: habitacion),
                  )
              : null,
          icon: const Icon(Icons.lock_open),
          label: const Text('Abrir Puerta'),
          style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => Navigator.pushNamed(context, '/room-service'),
          icon: const Icon(Icons.room_service),
          label: const Text('Solicitar Servicio a Habitación'),
          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16)),
        ),
      ],
    );
  }
}
