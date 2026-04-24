import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:table_calendar/table_calendar.dart';
import '../services/actividades_provider.dart';
import '../services/auth_provider.dart';
import '../models/actividad.dart';
import '../theme/app_theme.dart';

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
    WidgetsBinding.instance.addPostFrameCallback((_) {
    _cargarActividades();
  });
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
        actions: [
          IconButton(
            icon: const Icon(Icons.event_note_outlined),
            tooltip: 'Mis reservas',
            onPressed: () =>
                Navigator.of(context).pushNamed('/mis-reservas-actividades'),
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: _buildFiltrosCategorias(),
        ),
      ),
      body: actividadesProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : actividadesProvider.errorMessage != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.error_outline,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Error al cargar actividades',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      actividadesProvider.errorMessage!,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _cargarActividades,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Reintentar'),
                    ),
                  ],
                ),
              ),
            )
          : actividades.isEmpty
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.local_activity_outlined,
                      size: 64,
                      color: Colors.grey.shade400,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No hay actividades disponibles',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Las actividades aparecerán aquí cuando estén disponibles.',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _cargarActividades,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Actualizar'),
                    ),
                  ],
                ),
              ),
            )
          : ListView.builder(
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
    );
  }

  String _capitalizarCategoria(String categoria) {
    if (categoria.isEmpty) return categoria;
    return categoria[0].toUpperCase() + categoria.substring(1);
  }

  IconData _getIconForCategory(String categoria) {
    final cat = categoria.toLowerCase();
    if (cat.contains('gimnasio') || cat.contains('fitness'))
      return Icons.fitness_center;
    if (cat.contains('spa') || cat.contains('wellness')) return Icons.spa;
    if (cat.contains('restaurante') ||
        cat.contains('comida') ||
        cat.contains('food'))
      return Icons.restaurant;
    if (cat.contains('piscina') || cat.contains('pool')) return Icons.pool;
    if (cat.contains('tour') || cat.contains('excursion')) return Icons.tour;
    if (cat.contains('yoga') || cat.contains('meditacion'))
      return Icons.self_improvement;
    if (cat.contains('deporte') || cat.contains('sport')) return Icons.sports;
    if (cat.contains('entretenimiento') || cat.contains('entertainment'))
      return Icons.theater_comedy;
    return Icons.local_activity;
  }

  Widget _buildFiltrosCategorias() {
    final actividadesProvider = Provider.of<ActividadesProvider>(
      context,
      listen: false,
    );

    // Build dynamic categories from loaded activities
    final categoriasDisponibles = actividadesProvider.categorias;
    final List<Map<String, dynamic>> categorias = [
      {'id': null, 'nombre': 'Todas', 'icon': Icons.grid_view},
      ...categoriasDisponibles.map(
        (cat) => {
          'id': cat,
          'nombre': _capitalizarCategoria(cat),
          'icon': _getIconForCategory(cat),
        },
      ),
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

  const _TarjetaActividad({required this.actividad, required this.onTap});

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
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(color: AppTheme.textSecondary),
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
              const SizedBox(height: 8),
              if (actividad.ubicacion.isNotEmpty)
                Row(
                  children: [
                    Icon(Icons.location_on_outlined,
                        size: 14, color: AppTheme.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      actividad.ubicacion,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                  ],
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  if (actividad.requiereReserva)
                    Chip(
                      label: const Text(
                        'Reserva',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      avatar: const Icon(Icons.event, size: 16),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                    )
                  else
                    Chip(
                      label: const Text(
                        'Libre',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      avatar: const Icon(Icons.check_circle, size: 16),
                      backgroundColor: Colors.green.shade50,
                      labelStyle: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: Colors.green.shade700),
                    ),
                  if (actividad.duracionMinutos != null) ...[
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(
                        '${actividad.duracionMinutos} min',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      avatar: const Icon(Icons.timer_outlined, size: 16),
                      labelStyle: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
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
  bool _isSubmitting = false;
  final _notasController = TextEditingController();

  late final List<String> _horasDisponibles;

  @override
  void initState() {
    super.initState();
    _horasDisponibles = _generarHorasDisponibles();
  }

  @override
  void dispose() {
    _notasController.dispose();
    super.dispose();
  }

  List<String> _generarHorasDisponibles() {
    try {
      final apertura = _parseTimeSpan(widget.actividad.horarioApertura);
      final cierre = _parseTimeSpan(widget.actividad.horarioCierre);
      final paso = widget.actividad.duracionMinutos ?? 60;
      final List<String> horas = [];
      var current = apertura;
      while (current + paso <= cierre) {
        final h = current ~/ 60;
        final m = current % 60;
        horas.add('${h.toString().padLeft(2, '0')}:${m.toString().padLeft(2, '0')}');
        current += paso;
      }
      return horas.isNotEmpty ? horas : _fallbackHours();
    } catch (_) {
      return _fallbackHours();
    }
  }

  int _parseTimeSpan(String t) {
    final parts = t.split(':');
    final h = int.tryParse(parts[0]) ?? 0;
    final m = parts.length > 1 ? (int.tryParse(parts[1]) ?? 0) : 0;
    return h * 60 + m;
  }

  List<String> _fallbackHours() => [
        '08:00', '09:00', '10:00', '11:00', '12:00',
        '13:00', '14:00', '15:00', '16:00', '17:00', '18:00', '19:00', '20:00',
      ];

  double get _montoTotal =>
      (widget.actividad.precio ?? 0.0) * _numeroPersonas;

  @override
  Widget build(BuildContext context) {
    final actividad = widget.actividad;

    return DraggableScrollableSheet(
      initialChildSize: 0.92,
      minChildSize: 0.5,
      maxChildSize: 0.97,
      expand: false,
      builder: (context, scrollController) {
        return Column(
          children: [
            // Handle
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 4),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                controller: scrollController,
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Text(
                      actividad.nombre,
                      style: Theme.of(context).textTheme.headlineSmall
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),

                    // Info chips
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: [
                        if (actividad.ubicacion.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: actividad.ubicacion,
                          ),
                        if (actividad.duracionMinutos != null)
                          _InfoChip(
                            icon: Icons.timer_outlined,
                            label: '${actividad.duracionMinutos} min',
                          ),
                        _InfoChip(
                          icon: Icons.group_outlined,
                          label: 'Máx. ${actividad.capacidadMaxima} personas',
                        ),
                        if (actividad.precio != null && actividad.precio! > 0)
                          _InfoChip(
                            icon: Icons.attach_money,
                            label: '\$${actividad.precio!.toStringAsFixed(2)}/persona',
                            color: AppTheme.goldColor,
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),
                    const Divider(),
                    const SizedBox(height: 16),

                    // Fecha
                    Text('Selecciona la fecha',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TableCalendar(
                      firstDay: DateTime.now(),
                      lastDay: DateTime.now().add(const Duration(days: 60)),
                      focusedDay: _fechaSeleccionada,
                      selectedDayPredicate: (day) =>
                          isSameDay(_fechaSeleccionada, day),
                      onDaySelected: (selected, focused) {
                        setState(() {
                          _fechaSeleccionada = selected;
                          _horaSeleccionada = null;
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
                    Text('Selecciona la hora',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 4),
                    Text(
                      '${actividad.horarioApertura.substring(0, 5)} – '
                      '${actividad.horarioCierre.substring(0, 5)}',
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(color: AppTheme.textSecondary),
                    ),
                    const SizedBox(height: 12),
                    _horasDisponibles.isEmpty
                        ? const Text('No hay horarios disponibles')
                        : Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _horasDisponibles.map((hora) {
                              final isSelected = _horaSeleccionada == hora;
                              return ChoiceChip(
                                label: Text(hora),
                                selected: isSelected,
                                onSelected: (_) =>
                                    setState(() => _horaSeleccionada = hora),
                                selectedColor: AppTheme.primaryColor,
                                labelStyle: TextStyle(
                                  color: isSelected
                                      ? Colors.white
                                      : AppTheme.primaryColor,
                                ),
                              );
                            }).toList(),
                          ),

                    const SizedBox(height: 24),

                    // Número de personas
                    Text('Número de personas',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        IconButton(
                          onPressed: _numeroPersonas > 1
                              ? () => setState(() => _numeroPersonas--)
                              : null,
                          icon: const Icon(Icons.remove_circle_outline),
                          color: AppTheme.primaryColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '$_numeroPersonas',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _numeroPersonas < actividad.capacidadMaxima
                              ? () => setState(() => _numeroPersonas++)
                              : null,
                          icon: const Icon(Icons.add_circle_outline),
                          color: AppTheme.primaryColor,
                        ),
                        const Spacer(),
                        if (actividad.capacidadMaxima > 0)
                          Text(
                            'Máx. ${actividad.capacidadMaxima}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Notas especiales
                    Text('Notas especiales (opcional)',
                        style: Theme.of(context).textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    TextField(
                      controller: _notasController,
                      maxLines: 3,
                      maxLength: 300,
                      decoration: InputDecoration(
                        hintText: 'Alergias, preferencias, solicitudes...',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        contentPadding: const EdgeInsets.all(12),
                      ),
                    ),

                    const SizedBox(height: 8),

                    // Resumen de precio
                    if (actividad.precio != null && actividad.precio! > 0) ...[
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryColor.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.primaryColor.withOpacity(0.15),
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  '\$${actividad.precio!.toStringAsFixed(2)} × $_numeroPersonas persona${_numeroPersonas > 1 ? 's' : ''}',
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                                Text(
                                  '\$${_montoTotal.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            const Divider(height: 16),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: Theme.of(context)
                                        .textTheme
                                        .titleMedium
                                        ?.copyWith(fontWeight: FontWeight.bold)),
                                Text(
                                  '\$${_montoTotal.toStringAsFixed(2)}',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: AppTheme.primaryColor,
                                      ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // Botón confirmar
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: (_horaSeleccionada == null || _isSubmitting)
                            ? null
                            : _confirmar,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                        ),
                        child: _isSubmitting
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                'Confirmar Reserva',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _confirmar() async {
    if (_horaSeleccionada == null) return;
    setState(() => _isSubmitting = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final actividadesProvider =
        Provider.of<ActividadesProvider>(context, listen: false);

    final success = await actividadesProvider.reservarActividad(
      idActividad: widget.actividad.id,
      idUsuario: authProvider.usuario!.id,
      fecha: _fechaSeleccionada,
      hora: _horaSeleccionada!,
      numeroPersonas: _numeroPersonas,
      notas: _notasController.text.trim().isEmpty
          ? null
          : _notasController.text.trim(),
    );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    if (success) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('¡Reserva confirmada exitosamente!'),
          backgroundColor: Colors.green,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            actividadesProvider.errorMessage ?? 'Error al crear la reserva',
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppTheme.primaryColor;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: c.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: c.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: c),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: c,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
