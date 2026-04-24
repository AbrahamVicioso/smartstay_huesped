import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../services/reservas_actividades_provider.dart';
import '../models/api/reserva_actividad.dart';
import '../theme/app_theme.dart';

class MisReservasActividadesScreen extends StatefulWidget {
  const MisReservasActividadesScreen({super.key});

  @override
  State<MisReservasActividadesScreen> createState() => _MisReservasScreenState();
}

class _MisReservasScreenState extends State<MisReservasActividadesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
    Provider.of<ReservasActividadesProvider>(context, listen: false).cargarMisReservas();
  });
  }

  Future<void> _cargarReservas() async {
    final provider = Provider.of<ReservasActividadesProvider>(context, listen: false);
    await provider.cargarMisReservas();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Mis actividades'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          Consumer<ReservasActividadesProvider>(
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
        bottom: TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: Consumer<ReservasActividadesProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (provider.errorMessage != null) {
            return _ErrorView(
              message: provider.errorMessage!,
              onRetry: _cargarReservas,
            );
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Tab Activas
              _ReservasList(
                reservas: provider.reservasActivas,
                emptyMessage: 'No tienes reservas activas',
                emptySubMessage: 'Tus reservas confirmadas aparecerán aquí',
                emptyIcon: Icons.event_available_outlined,
                onRefresh: _cargarReservas,
              ),
              // Tab Historial
              _ReservasList(
                reservas: provider.reservasPasadas,
                emptyMessage: 'Sin historial de reservas',
                emptySubMessage:
                    'Las reservas completadas o canceladas aparecerán aquí',
                emptyIcon: Icons.history,
                onRefresh: _cargarReservas,
                showCancelButton: false,
              ),
            ],
          );
        },
      ),
    );
  }
}

// Lista de reservas con pull-to-refresh
class _ReservasList extends StatelessWidget {
  final List<ReservaActividadApi> reservas;
  final String emptyMessage;
  final String emptySubMessage;
  final IconData emptyIcon;
  final Future<void> Function() onRefresh;
  final bool showCancelButton;

  const _ReservasList({
    required this.reservas,
    required this.emptyMessage,
    required this.emptySubMessage,
    required this.emptyIcon,
    required this.onRefresh,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (reservas.isEmpty) {
      return _EmptyState(
        icon: emptyIcon,
        message: emptyMessage,
        subMessage: emptySubMessage,
      );
    }

    return RefreshIndicator(
      onRefresh: onRefresh,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: reservas.length,
        itemBuilder: (context, index) {
          return _ReservaActividadCard(
            reserva: reservas[index],
            showCancelButton: showCancelButton,
          );
        },
      ),
    );
  }
}

// Tarjeta individual de reserva de actividad
class _ReservaActividadCard extends StatelessWidget {
  final ReservaActividadApi reserva;
  final bool showCancelButton;

  const _ReservaActividadCard({
    required this.reserva,
    this.showCancelButton = true,
  });

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('dd MMM yyyy', 'es');
    final estado = reserva.estado;
    final estadoColor = _getEstadoColor(estado);
    final estadoIcon = _getEstadoIcon(estado);

    // Formatear hora
    String horaFormateada = reserva.horaReserva;
    if (horaFormateada.length >= 5) {
      horaFormateada = horaFormateada.substring(0, 5);
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header con estado
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: estadoColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(estadoIcon, color: estadoColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Reserva #${reserva.reservaActividadId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppTheme.textPrimary,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: estadoColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    estado,
                    style: TextStyle(
                      color: estadoColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Body con detalles
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                _DetailRow(
                  icon: Icons.local_activity_outlined,
                  label: 'Actividad',
                  value: Provider.of<ReservasActividadesProvider>(context, listen: false)
                      .getNombreActividad(reserva.actividadId),
                ),
                const SizedBox(height: 12),

                // Fecha y Hora de la reserva
                Row(
                  children: [
                    Expanded(
                      child: _DateCard(
                        label: 'Fecha',
                        date: dateFormat.format(reserva.fechaReserva),
                        icon: Icons.calendar_today,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateCard(
                        label: 'Hora',
                        date: horaFormateada,
                        icon: Icons.access_time,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Personas
                _DetailRow(
                  icon: Icons.people_outline,
                  label: 'Personas',
                  value: '${reserva.numeroPersonas}',
                ),
                const SizedBox(height: 16),

                // Divider
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // Monto Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Monto Total',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '\$${reserva.montoTotal.toStringAsFixed(2)}',
                          style: Theme.of(context).textTheme.titleLarge
                              ?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: AppTheme.primaryColor,
                              ),
                        ),
                      ],
                    ),
                  ],
                ),

                // Notas especiales si hay
                if (reserva.notasEspeciales != null &&
                    reserva.notasEspeciales!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppTheme.backgroundColor,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.notes,
                          size: 18,
                          color: AppTheme.textSecondary,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            reserva.notasEspeciales!,
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Botón de cancelar reserva - solo para reservas activas
                if (showCancelButton && _esReservaActiva(reserva.estado)) ...[
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () =>
                          _mostrarDialogoCancelar(context, reserva),
                      icon: const Icon(Icons.cancel_outlined),
                      label: const Text('Cancelar Reserva'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red,
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _mostrarDialogoCancelar(
    BuildContext context,
    ReservaActividadApi reserva,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancelar Reserva'),
        content: Text(
          '¿Está seguro que desea cancelar la reserva #${reserva.reservaActividadId}?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('No, mantener'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final provider = Provider.of<ReservasActividadesProvider>(
                context,
                listen: false,
              );
              final success = await provider.cancelarReserva(
                reserva.reservaActividadId,
              );
              if (success && context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Reserva cancelada exitosamente'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      provider.errorMessage ?? 'Error al cancelar la reserva',
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  Color _getEstadoColor(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return Colors.green;
      case 'checkin':
        return Colors.blue;
      case 'checkout':
      case 'completada':
        return Colors.grey;
      case 'cancelada':
        return Colors.red;
      case 'pendiente':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  bool _esReservaActiva(String estado) {
    final estadoLower = estado.toLowerCase();
    return estadoLower == 'confirmada' ||
        estadoLower == 'checkin' ||
        estadoLower == 'pendiente';
  }

  IconData _getEstadoIcon(String estado) {
    switch (estado.toLowerCase()) {
      case 'confirmada':
        return Icons.check_circle_outline;
      case 'checkin':
        return Icons.login;
      case 'checkout':
      case 'completada':
        return Icons.done_all;
      case 'cancelada':
        return Icons.cancel_outlined;
      case 'pendiente':
        return Icons.schedule;
      default:
        return Icons.info_outline;
    }
  }
}

// Componentes auxiliares

class _DateCard extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;
  final Color color;

  const _DateCard({
    required this.label,
    required this.date,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Text(
                label,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: color,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            date,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: AppTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
        ),
        Text(
          value,
          style: Theme.of(
            context,
          ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String message;
  final String subMessage;

  const _EmptyState({
    required this.icon,
    required this.message,
    required this.subMessage,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppTheme.primaryColor.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: AppTheme.primaryColor),
            ),
            const SizedBox(height: 20),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              subMessage,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.red.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Error al cargar reservas',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppTheme.textSecondary),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
