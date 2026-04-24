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
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // Hero Image with overlay buttons
          SliverAppBar(
            expandedHeight: 280,
            floating: false,
            pinned: true,
            backgroundColor: AppColors.background,
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.background.withOpacity(0.9),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                icon: const Icon(Icons.arrow_back, color: AppColors.secondary),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.background.withOpacity(0.9),
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  icon: const Icon(Icons.share, color: AppColors.secondary),
                  onPressed: () {},
                ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Hero image placeholder
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          AppColors.primary.withOpacity(0.8),
                          AppColors.primaryDark,
                        ],
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.hotel,
                        size: 80,
                        color: Colors.white24,
                      ),
                    ),
                  ),
                  // Bottom gradient overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 100,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.background.withOpacity(0.8),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPadding(
            padding: const EdgeInsets.all(24),
            sliver: SliverList(
              delegate: SliverChildListDelegate([
                // Room name and price
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Habitación ${_hab.numeroHabitacion}',
                            style: Theme.of(context).textTheme.displayMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _hab.tipoHabitacion,
                            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '\$${_hab.precioPorNoche.toStringAsFixed(0)}',
                          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          '/noche',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // Rating and location
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.rating.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star, color: AppColors.rating, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            '4.8',
                            style: Theme.of(context).textTheme.labelMedium?.copyWith(
                              color: AppColors.rating,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      'Piso ${_hab.piso}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '•',
                      style: TextStyle(color: AppColors.textSecondary),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${_hab.capacidadMaxima} huéspedes',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 32),

                // Facilities section
                Text(
                  'Facilidades',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 16),
                _buildFacilitiesGrid(),

                const SizedBox(height: 32),

                // Description
                Text(
                  'Descripción',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Text(
                  'Habitación elegante y espaciosa con todas las comodidades modernas para una estancia confortable. Dispone de cama king size, área de trabajo, minibar y baño privado con artículos de tocador de alta calidad.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppColors.textSecondary,
                    height: 1.6,
                  ),
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                ),
                TextButton(
                  onPressed: () {},
                  child: const Text('Leer más'),
                ),

                const SizedBox(height: 24),

                // Reservation details if exists
                if (habitacion != null && _hab.reservaId != null) ...[
                  _buildReservaDetails(context, dateFormat),
                  const SizedBox(height: 24),
                ],

                // Spacer for fixed bottom buttons
                const SizedBox(height: 100),
              ]),
            ),
          ),
        ],
      ),
      // Fixed bottom buttons
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: AppColors.background,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.directions, size: 20),
                  label: const Text('Direcciones'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                flex: 2,
                child: ElevatedButton.icon(
                  onPressed: habitacion != null
                      ? () => showModalBottomSheet(
                            context: context,
                            isScrollControlled: true,
                            backgroundColor: Colors.transparent,
                            builder: (context) => AperturaOpcionesSheet(habitacionData: habitacion),
                          )
                      : null,
                  icon: const Icon(Icons.lock_open, size: 20),
                  label: const Text('Abrir Puerta'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFacilitiesGrid() {
    final facilities = [
      {'icon': Icons.wifi, 'label': 'WiFi'},
      {'icon': Icons.ac_unit, 'label': 'A/C'},
      {'icon': Icons.pool, 'label': 'Piscina'},
      {'icon': Icons.restaurant, 'label': 'Restaurante'},
      {'icon': Icons.fitness_center, 'label': 'Gimnasio'},
      {'icon': Icons.spa, 'label': 'Spa'},
    ];

    return Wrap(
      spacing: 16,
      runSpacing: 16,
      children: facilities.map((f) {
        return Container(
          width: 100,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
          decoration: BoxDecoration(
            color: AppColors.backgroundSecondary,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            children: [
              Icon(f['icon'] as IconData, color: AppColors.primary, size: 24),
              const SizedBox(height: 8),
              Text(
                f['label'] as String,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildReservaDetails(BuildContext context, DateFormat dateFormat) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.confirmation_number, color: AppColors.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Reserva #${_hab.reservaId}',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildDateColumn(
                  context,
                  'Check-in',
                  _hab.fechaCheckIn != null ? dateFormat.format(_hab.fechaCheckIn!) : '-',
                  Icons.login,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildDateColumn(
                  context,
                  'Check-out',
                  _hab.fechaCheckOut != null ? dateFormat.format(_hab.fechaCheckOut!) : '-',
                  Icons.logout,
                ),
              ),
            ],
          ),
          const Divider(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.nightlight_round, color: AppColors.primary, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    '${_hab.diasRestantes} noches restantes',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.pin, color: AppColors.primary, size: 16),
                    const SizedBox(width: 4),
                    Text(
                      _hab.pinAcceso ?? '------',
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDateColumn(BuildContext context, String label, String date, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.textSecondary, size: 20),
        const SizedBox(height: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          date,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
