import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notificaciones_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';
import 'actividades_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import '../widgets/habitacion_card.dart';
import 'mis_reservas_screen.dart';
import 'habitacion_detalle_screen.dart';
import 'chat_recepcion_screen.dart';
import 'checkin_checkout_screen.dart';
import 'hotel_info_screen.dart';
import 'room_service_screen.dart';
import 'mis_habitaciones_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedIndex = 0;

  @override
  void initState() {
    super.initState();
    _cargarDatos();
  }

  Future<void> _cargarDatos() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final notifProvider = Provider.of<NotificacionesProvider>(
      context,
      listen: false,
    );

    if (authProvider.usuario != null) {
      await notifProvider.cargarNotificaciones(authProvider.usuario!.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          MisReservasScreen(),
          _ActividadesTab(),
          _NotificacionesTab(),
          _PerfilTab(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.home_outlined),
            selectedIcon: const Icon(Icons.home),
            label: 'Inicio',
          ),
          NavigationDestination(
            icon: const Icon(Icons.book_outlined),
            selectedIcon: const Icon(Icons.book),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: const Icon(Icons.local_activity_outlined),
            selectedIcon: const Icon(Icons.local_activity),
            label: 'Actividades',
          ),
          NavigationDestination(
            icon: Consumer<NotificacionesProvider>(
              builder: (context, notifProvider, child) {
                final count = notifProvider.cantidadNoLeidas;
                return Badge(
                  label: Text('$count'),
                  isLabelVisible: count > 0,
                  child: const Icon(Icons.notifications_outlined),
                );
              },
            ),
            selectedIcon: const Icon(Icons.notifications),
            label: 'Notificaciones',
          ),
          NavigationDestination(
            icon: const Icon(Icons.person_outline),
            selectedIcon: const Icon(Icons.person),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}

// Dashboard Tab
class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.usuario;

    // Mostrar todas las habitaciones del cliente logueado (sin requerir check-in)
    final habitaciones = authProvider.habitacionesDetalladas;

    final nombreHuesped = authProvider.nombreHuesped;

    return CustomScrollView(
      slivers: [
        // App Bar
        SliverAppBar(
          expandedHeight: 120,
          floating: false,
          pinned: true,
          flexibleSpace: FlexibleSpaceBar(
            title: Text(
              'Hola, ${nombreHuesped.split(' ').first}',
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            background: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppTheme.backgroundColor,
                    AppTheme.goldColor.withOpacity(0.1),
                  ],
                ),
              ),
            ),
          ),
        ),

        SliverPadding(
          padding: const EdgeInsets.all(16),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              // Mis Habitaciones - siempre mostrar para usuarios logueados
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Mis Habitaciones',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  if (habitaciones.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryColor,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${habitaciones.length}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              // Lista de Habitaciones (máximo 2) + Botón para ver todas
              if (habitaciones.isNotEmpty) ...[
                ...habitaciones
                    .take(2)
                    .map(
                      (habitacion) => HabitacionCard(
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
                      ),
                    ),
                const SizedBox(height: 8),
                Center(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const MisHabitacionesScreen(),
                        ),
                      );
                    },
                    icon: const Icon(Icons.hotel),
                    label: Text(
                      'Ver todas las habitaciones (${habitaciones.length})',
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryColor,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 12,
                      ),
                    ),
                  ),
                ),
              ] else ...[
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      children: [
                        Icon(
                          Icons.hotel_outlined,
                          size: 48,
                          color: Colors.grey.shade400,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'No tienes habitaciones asignadas',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Las habitaciones aparecerán automáticamente cuando estén disponibles',
                          style: Theme.of(context).textTheme.bodySmall
                              ?.copyWith(color: AppTheme.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 24),

              // Accesos Rápidos
              Text(
                'Accesos Rápidos',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _AccesosRapidos(),
              const SizedBox(height: 24),

              // Servicios Destacados
              Text(
                'Servicios Destacados',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _ServiciosDestacados(),
            ]),
          ),
        ),
      ],
    );
  }
}

class _TarjetaHabitacion extends StatelessWidget {
  final reserva;

  const _TarjetaHabitacion({required this.reserva});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryColor, AppTheme.secondaryColor],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Mi Habitación',
                style: Theme.of(
                  context,
                ).textTheme.titleLarge?.copyWith(color: Colors.white),
              ),
              Icon(Icons.hotel, color: AppTheme.goldColor, size: 32),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text(
                'Habitación ',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: Colors.white70),
              ),
              Text(
                reserva.numeroHabitacion,
                style: Theme.of(context).textTheme.displayMedium?.copyWith(
                  color: AppTheme.goldColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reserva.tipoHabitacion,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Divider(color: Colors.white24),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _InfoColumn(
                icon: Icons.event,
                label: 'Check-out',
                value: DateFormat('dd MMM', 'es').format(reserva.fechaSalida),
              ),
              _InfoColumn(
                icon: Icons.nightlight_round,
                label: 'Noches restantes',
                value: '${reserva.diasRestantes}',
              ),
              _InfoColumn(
                icon: Icons.pin,
                label: 'PIN',
                value: reserva.pinAcceso,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _InfoColumn extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoColumn({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.bodySmall?.copyWith(color: Colors.white60),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}

class _AccesosRapidos extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final accesos = [
      {
        'icon': Icons.room_service,
        'label': 'Servicio a Habitación',
        'color': Colors.orange,
        'route': '/room-service',
      },
      {
        'icon': Icons.phone,
        'label': 'Recepción',
        'color': Colors.blue,
        'route': '/chat-recepcion',
      },
      {
        'icon': Icons.restaurant,
        'label': 'Información del hotel',
        'color': Colors.green,
        'route': '/hotel-info',
      },
      {
        'icon': Icons.spa,
        'label': 'Check-in/out',
        'color': Colors.purple,
        'route': '/checkin-checkout',
      },
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 1.5,
      ),
      itemCount: accesos.length,
      itemBuilder: (context, index) {
        final acceso = accesos[index];
        return Card(
          child: InkWell(
            onTap: () {
              Navigator.pushNamed(context, acceso['route'] as String);
            },
            borderRadius: BorderRadius.circular(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  acceso['icon'] as IconData,
                  size: 32,
                  color: acceso['color'] as Color,
                ),
                const SizedBox(height: 8),
                Text(
                  acceso['label'] as String,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ServiciosDestacados extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final servicios = [
      {
        'titulo': 'Piscina Infinity',
        'descripcion': 'Disfrute de nuestra piscina con vista panorámica',
        'icon': Icons.pool,
      },
      {
        'titulo': 'Gimnasio 24/7',
        'descripcion': 'Equipamiento de última generación',
        'icon': Icons.fitness_center,
      },
    ];

    return Column(
      children: servicios.map((servicio) {
        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: AppTheme.primaryColor.withOpacity(0.1),
              child: Icon(
                servicio['icon'] as IconData,
                color: AppTheme.primaryColor,
              ),
            ),
            title: Text(servicio['titulo'] as String),
            subtitle: Text(servicio['descripcion'] as String),
            trailing: const Icon(Icons.arrow_forward_ios, size: 16),
            onTap: () {
              Navigator.pushNamed(context, '/hotel-info');
            },
          ),
        );
      }).toList(),
    );
  }
}

// Tabs reales
class _ActividadesTab extends StatelessWidget {
  const _ActividadesTab();

  @override
  Widget build(BuildContext context) {
    return const ActividadesScreen();
  }
}

class _NotificacionesTab extends StatelessWidget {
  const _NotificacionesTab();

  @override
  Widget build(BuildContext context) {
    return const NotificacionesScreen();
  }
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab();

  @override
  Widget build(BuildContext context) {
    return const PerfilScreen();
  }
}
