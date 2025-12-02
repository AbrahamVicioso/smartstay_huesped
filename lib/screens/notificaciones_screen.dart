import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/notificaciones_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class NotificacionesScreen extends StatelessWidget {
  const NotificacionesScreen({super.key});

  Color _getColorByTipo(String tipo) {
    switch (tipo) {
      case 'acceso':
        return Colors.orange;
      case 'recordatorio':
        return Colors.blue;
      case 'actividad':
        return Colors.green;
      case 'sistema':
      default:
        return AppTheme.primaryColor;
    }
  }

  IconData _getIconByTipo(String tipo) {
    switch (tipo) {
      case 'acceso':
        return Icons.lock_open;
      case 'recordatorio':
        return Icons.alarm;
      case 'actividad':
        return Icons.local_activity;
      case 'sistema':
      default:
        return Icons.info;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notifProvider = Provider.of<NotificacionesProvider>(context);
    final notificaciones = notifProvider.notificaciones;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notificaciones'),
        actions: [
          if (notifProvider.cantidadNoLeidas > 0)
            TextButton(
              onPressed: () {
                notifProvider.marcarTodasComoLeidas();
              },
              child: const Text('Marcar todas como leídas'),
            ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              _mostrarConfiguracion(context);
            },
          ),
        ],
      ),
      body: notificaciones.isEmpty
          ? _buildEmptyState(context)
          : ListView.builder(
              itemCount: notificaciones.length,
              itemBuilder: (context, index) {
                final notificacion = notificaciones[index];
                return Dismissible(
                  key: Key(notificacion.id),
                  background: Container(
                    color: Colors.red,
                    alignment: Alignment.centerRight,
                    padding: const EdgeInsets.only(right: 16),
                    child: const Icon(
                      Icons.delete,
                      color: Colors.white,
                    ),
                  ),
                  direction: DismissDirection.endToStart,
                  onDismissed: (_) {
                    notifProvider.eliminarNotificacion(notificacion.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Notificación eliminada'),
                      ),
                    );
                  },
                  child: Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    elevation: notificacion.leida ? 0 : 2,
                    color: notificacion.leida
                        ? Colors.grey.shade50
                        : Colors.white,
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: _getColorByTipo(notificacion.tipo)
                            .withOpacity(0.2),
                        child: Icon(
                          _getIconByTipo(notificacion.tipo),
                          color: _getColorByTipo(notificacion.tipo),
                        ),
                      ),
                      title: Text(
                        notificacion.titulo,
                        style: TextStyle(
                          fontWeight: notificacion.leida
                              ? FontWeight.normal
                              : FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(notificacion.mensaje),
                          const SizedBox(height: 4),
                          Text(
                            _formatearFecha(notificacion.fecha),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: AppTheme.textSecondary,
                            ),
                          ),
                          if (notificacion.datos != null &&
                              notificacion.tipo == 'acceso') ...[
                            const SizedBox(height: 8),
                            _buildDetallesAcceso(context, notificacion.datos!),
                          ],
                        ],
                      ),
                      trailing: !notificacion.leida
                          ? const Icon(
                              Icons.circle,
                              color: AppTheme.accentColor,
                              size: 12,
                            )
                          : null,
                      onTap: () {
                        if (!notificacion.leida) {
                          notifProvider.marcarComoLeida(notificacion.id);
                        }
                      },
                    ),
                  ),
                );
              },
            ),
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 16),
          Text(
            'No hay notificaciones',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Cuando reciba notificaciones aparecerán aquí',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetallesAcceso(BuildContext context, Map<String, dynamic> datos) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildInfoRow(
            context,
            Icons.person,
            'Personal',
            datos['personal'] ?? 'N/A',
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            context,
            Icons.info_outline,
            'Motivo',
            datos['motivo'] ?? 'N/A',
          ),
          const SizedBox(height: 4),
          _buildInfoRow(
            context,
            Icons.access_time,
            'Hora',
            datos['hora'] ?? 'N/A',
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context,
    IconData icon,
    String label,
    String value,
  ) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.orange),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: Colors.orange.shade900,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.orange.shade900,
            ),
          ),
        ),
      ],
    );
  }

  String _formatearFecha(DateTime fecha) {
    final ahora = DateTime.now();
    final diferencia = ahora.difference(fecha);

    if (diferencia.inMinutes < 1) {
      return 'Ahora';
    } else if (diferencia.inHours < 1) {
      return 'Hace ${diferencia.inMinutes} min';
    } else if (diferencia.inDays < 1) {
      return 'Hace ${diferencia.inHours} h';
    } else if (diferencia.inDays == 1) {
      return 'Ayer';
    } else {
      return DateFormat('dd/MM/yyyy HH:mm').format(fecha);
    }
  }

  void _mostrarConfiguracion(BuildContext context) {
    final notifProvider = Provider.of<NotificacionesProvider>(context, listen: false);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Consumer<NotificacionesProvider>(
          builder: (context, provider, child) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Configuración de Notificaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 24),
                  SwitchListTile(
                    title: const Text('Notificaciones activas'),
                    subtitle: const Text(
                      'Recibir notificaciones push',
                    ),
                    value: provider.notificacionesActivas,
                    onChanged: (value) {
                      provider.toggleNotificaciones(value);
                    },
                  ),
                  const Divider(),
                  SwitchListTile(
                    title: const Text('Modo No Molestar'),
                    subtitle: Text(
                      '${provider.horaInicioNoMolestar} - ${provider.horaFinNoMolestar}',
                    ),
                    value: provider.modoNoMolestar,
                    onChanged: (value) {
                      provider.toggleModoNoMolestar(value);
                    },
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
