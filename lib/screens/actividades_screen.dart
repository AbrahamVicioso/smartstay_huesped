import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/actividades_provider.dart';
import '../services/auth_provider.dart';
import '../models/actividad.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class ActividadesScreen extends StatefulWidget {
  const ActividadesScreen({super.key});

  @override
  State<ActividadesScreen> createState() => _ActividadesScreenState();
}

class _ActividadesScreenState extends State<ActividadesScreen> {
  String? _categoriaSeleccionada;

  @override
  void initState() {
    super.initState();
    _cargarActividades();
  }

  Future<void> _cargarActividades() async {
    final actividadesProvider = Provider.of<ActividadesProvider>(
      context,
      listen: false,
    );
    await actividadesProvider.cargarActividades();
  }

  @override
  Widget build(BuildContext context) {
    final actividadesProvider = Provider.of<ActividadesProvider>(context);
    final actividades = _categoriaSeleccionada == null
        ? actividadesProvider.actividades
        : actividadesProvider.filtrarPorCategoria(_categoriaSeleccionada!);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Actividades y Servicios'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFiltrosCategorias(),
        ),
      ),
      body: actividadesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: actividades.length,
                    itemBuilder: (context, index) {
                      final actividad = actividades[index];
                      return _TarjetaActividad(
                        actividad: actividad,
                        onTap: () {
                          if (actividad.requiereReserva) {
                            _mostrarDialogoReserva(context, actividad);
                          } else {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  '${actividad.nombre} no requiere reserva. ¡Disfrute cuando desee!',
                                ),
                              ),
                            );
                          }
                        },
                      );
                    },
                  ),
                ),
                // Mis Reservas
                if (actividadesProvider.misReservas.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, -5),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Mis Reservas (${actividadesProvider.misReservas.length})',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 80,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: actividadesProvider.misReservas.length,
                            itemBuilder: (context, index) {
                              final reserva = actividadesProvider.misReservas[index];
                              final actividad = actividadesProvider
                                  .obtenerActividadPorId(reserva.idActividad);
                              return _TarjetaReserva(
                                reserva: reserva,
                                actividad: actividad,
                                onCancelar: () async {
                                  final confirmado = await _confirmarCancelacion(context);
                                  if (confirmado) {
                                    await actividadesProvider
                                        .cancelarReserva(reserva.id);
                                    if (context.mounted) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Reserva cancelada'),
                                        ),
                                      );
                                    }
                                  }
                                },
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildFiltrosCategorias() {
    final categorias = [
      {'id': null, 'nombre': 'Todas', 'icon': Icons.grid_view},
      {'id': 'gimnasio', 'nombre': 'Gimnasio', 'icon': Icons.fitness_center},
      {'id': 'spa', 'nombre': 'Spa', 'icon': Icons.spa},
      {'id': 'restaurante', 'nombre': 'Restaurante', 'icon': Icons.restaurant},
      {'id': 'piscina', 'nombre': 'Piscina', 'icon': Icons.pool},
      {'id': 'tour', 'nombre': 'Tours', 'icon': Icons.tour},
    ];

    return SizedBox(
      height: 60,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: categorias.length,
        itemBuilder: (context, index) {
          final categoria = categorias[index];
          final isSelected = _categoriaSeleccionada == categoria['id'];

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                children: [
                  Icon(
                    categoria['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : AppTheme.primaryColor,
                  ),
                  const SizedBox(width: 4),
                  Text(categoria['nombre'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _categoriaSeleccionada = categoria['id'] as String?;
                });
              },
              backgroundColor: Colors.white,
              selectedColor: AppTheme.primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : AppTheme.primaryColor,
              ),
            ),
          );
        },
      ),
    );
  }

  Future<bool> _confirmarCancelacion(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cancelar Reserva'),
            content: const Text('¿Está seguro que desea cancelar esta reserva?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('No'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                child: const Text('Sí, cancelar'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _mostrarDialogoReserva(BuildContext context, Actividad actividad) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _FormularioReserva(actividad: actividad),
    );
  }
}

class _TarjetaActividad extends StatelessWidget {
  final Actividad actividad;
  final VoidCallback onTap;

  const _TarjetaActividad({
    required this.actividad,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 28,
                    backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
                    child: Icon(
                      _getIconData(actividad.icono),
                      color: AppTheme.primaryColor,
                      size: 28,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          actividad.nombre,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.access_time,
                              size: 14,
                              color: AppTheme.textSecondary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              '${actividad.horarioApertura} - ${actividad.horarioCierre}',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (actividad.precio != null)
                    Text(
                      '\$${actividad.precio!.toStringAsFixed(2)}',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: AppTheme.goldColor,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              Text(
                actividad.descripcion,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  if (actividad.requiereReserva)
                    Chip(
                      label: const Text('Requiere Reserva'),
                      avatar: const Icon(Icons.event, size: 16),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Chip(
                      label: const Text('Acceso Libre'),
                      avatar: const Icon(Icons.check_circle, size: 16),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.green.shade700,
                      ),
                    ),
                  const Spacer(),
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 16,
                    color: AppTheme.textSecondary,
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIconData(String iconName) {
    const iconMap = {
      'fitness_center': Icons.fitness_center,
      'spa': Icons.spa,
      'restaurant': Icons.restaurant,
      'pool': Icons.pool,
      'tour': Icons.tour,
      'self_improvement': Icons.self_improvement,
    };
    return iconMap[iconName] ?? Icons.local_activity;
  }
}

class _TarjetaReserva extends StatelessWidget {
  final ReservaActividad reserva;
  final Actividad? actividad;
  final VoidCallback onCancelar;

  const _TarjetaReserva({
    required this.reserva,
    required this.actividad,
    required this.onCancelar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      actividad?.nombre ?? 'Actividad',
                      style: Theme.of(context).textTheme.titleSmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 16),
                    onPressed: onCancelar,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '${DateFormat('dd MMM', 'es').format(reserva.fecha)} - ${reserva.hora}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FormularioReserva extends StatefulWidget {
  final Actividad actividad;

  const _FormularioReserva({required this.actividad});

  @override
  State<_FormularioReserva> createState() => _FormularioReservaState();
}

class _FormularioReservaState extends State<_FormularioReserva> {
  DateTime _fechaSeleccionada = DateTime.now();
  String? _horaSeleccionada;
  int _numeroPersonas = 1;

  final List<String> _horasDisponibles = [
    '09:00', '10:00', '11:00', '12:00',
    '13:00', '14:00', '15:00', '16:00',
    '17:00', '18:00', '19:00', '20:00',
  ];

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reservar ${widget.actividad.nombre}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                const SizedBox(height: 24),

                // Calendario
                TableCalendar(
                  firstDay: DateTime.now(),
                  lastDay: DateTime.now().add(const Duration(days: 30)),
                  focusedDay: _fechaSeleccionada,
                  selectedDayPredicate: (day) =>
                      isSameDay(_fechaSeleccionada, day),
                  onDaySelected: (selectedDay, focusedDay) {
                    setState(() {
                      _fechaSeleccionada = selectedDay;
                    });
                  },
                  calendarStyle: CalendarStyle(
                    selectedDecoration: const BoxDecoration(
                      color: AppTheme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    todayDecoration: BoxDecoration(
                      color: AppTheme.primaryColor.withOpacity(0.3),
                      shape: BoxShape.circle,
                    ),
                  ),
                  headerStyle: const HeaderStyle(
                    formatButtonVisible: false,
                    titleCentered: true,
                  ),
                ),

                const SizedBox(height: 24),

                // Hora
                Text(
                  'Hora',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _horasDisponibles.map((hora) {
                    final isSelected = _horaSeleccionada == hora;
                    return ChoiceChip(
                      label: Text(hora),
                      selected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          _horaSeleccionada = hora;
                        });
                      },
                      selectedColor: AppTheme.primaryColor,
                      labelStyle: TextStyle(
                        color: isSelected ? Colors.white : AppTheme.primaryColor,
                      ),
                    );
                  }).toList(),
                ),

                const SizedBox(height: 24),

                // Número de personas
                Text(
                  'Número de personas',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    IconButton(
                      onPressed: _numeroPersonas > 1
                          ? () {
                              setState(() {
                                _numeroPersonas--;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.remove_circle_outline),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      '$_numeroPersonas',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(width: 16),
                    IconButton(
                      onPressed: _numeroPersonas < widget.actividad.capacidadMaxima
                          ? () {
                              setState(() {
                                _numeroPersonas++;
                              });
                            }
                          : null,
                      icon: const Icon(Icons.add_circle_outline),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Botón confirmar
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _horaSeleccionada == null
                        ? null
                        : () async {
                            final authProvider = Provider.of<AuthProvider>(
                              context,
                              listen: false,
                            );
                            final actividadesProvider =
                                Provider.of<ActividadesProvider>(
                              context,
                              listen: false,
                            );

                            final success = await actividadesProvider.reservarActividad(
                              idActividad: widget.actividad.id,
                              idUsuario: authProvider.usuario!.id,
                              fecha: _fechaSeleccionada,
                              hora: _horaSeleccionada!,
                              numeroPersonas: _numeroPersonas,
                            );

                            if (success && context.mounted) {
                              Navigator.of(context).pop();
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Reserva confirmada exitosamente'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            }
                          },
                    child: const Text('Confirmar Reserva'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
