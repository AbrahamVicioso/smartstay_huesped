import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../theme/app_theme.dart';
import 'apertura_nfc_modal.dart';
import 'apertura_remota_modal.dart';
import 'apertura_pin_modal.dart';

class AperturaOpcionesSheet extends StatelessWidget {
  final Reserva reserva;

  const AperturaOpcionesSheet({
    super.key,
    required this.reserva,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador de arrastre
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Título
          Row(
            children: [
              Icon(
                Icons.meeting_room,
                color: AppTheme.primaryColor,
                size: 28,
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Abrir Habitación',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(
                    'Habitación ${reserva.numeroHabitacion}',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Opciones
          _OpcionApertura(
            icon: Icons.wifi,
            titulo: 'Abrir Remoto',
            descripcion: 'Abrir desde tu ubicación actual',
            color: Colors.blue,
            onTap: () {
              Navigator.pop(context);
              _mostrarAperturaRemota(context);
            },
          ),

          const SizedBox(height: 12),

          _OpcionApertura(
            icon: Icons.nfc,
            titulo: 'Abrir con NFC',
            descripcion: 'Acerca tu dispositivo al lector',
            color: Colors.orange,
            onTap: () {
              Navigator.pop(context);
              _mostrarAperturaNFC(context);
            },
          ),

          const SizedBox(height: 12),

          _OpcionApertura(
            icon: Icons.pin,
            titulo: 'Obtener PIN',
            descripcion: 'Ver código de acceso',
            color: AppTheme.goldColor,
            onTap: () {
              Navigator.pop(context);
              _mostrarPIN(context);
            },
          ),

          const SizedBox(height: 16),

          // Botón cancelar
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  void _mostrarAperturaRemota(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AperturaRemotaModal(reserva: reserva),
    );
  }

  void _mostrarAperturaNFC(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AperturaNFCModal(reserva: reserva),
    );
  }

  void _mostrarPIN(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AperturaPinModal(reserva: reserva),
    );
  }
}

class _OpcionApertura extends StatelessWidget {
  final IconData icon;
  final String titulo;
  final String descripcion;
  final Color color;
  final VoidCallback onTap;

  const _OpcionApertura({
    required this.icon,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.3)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      descripcion,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
