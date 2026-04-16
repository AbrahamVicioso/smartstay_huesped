import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notificaciones_provider.dart';
import '../theme/app_theme.dart';
import 'actividades_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'mis_reservas_screen.dart';
import 'habitacion_detalle_screen.dart';
import 'mis_habitaciones_screen.dart';
import '../services/reservas_hotel_provider.dart';
import '../models/reserva_hotel.dart';
import 'reserva_detalle_screen.dart';
import 'mis_reservashotel_screen.dart';

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
      backgroundColor: const Color(0xFFF8FAFC),
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          MisReservasScreen(),
          MisReservasHotelScreen(),
          _ActividadesTab(),
          _NotificacionesTab(),
          _PerfilTab(),
        ],
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.background,
        boxShadow: AppShadows.bottomNavShadow,
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.home_outlined,
                activeIcon: Icons.home_rounded,
                label: 'Inicio',
                isActive: _selectedIndex == 0,
                onTap: () => setState(() => _selectedIndex = 0),
              ),
              _NavItem(
                icon: Icons.bookmark_outline_rounded,
                activeIcon: Icons.bookmark_rounded,
                label: 'Actividades',
                isActive: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 1),
              ),
               _NavItem(
                icon: Icons.bookmark_outline_rounded,
                activeIcon: Icons.bookmark_rounded,
                label: 'Mis reservas',
                isActive: _selectedIndex == 1,
                onTap: () => setState(() => _selectedIndex = 2),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                activeIcon: Icons.explore_rounded,
                label: 'Explorar',
                isActive: _selectedIndex == 2,
                onTap: () => setState(() => _selectedIndex = 3),
              ),
              Consumer<NotificacionesProvider>(
                builder: (context, notifProvider, child) {
                  return _NavItem(
                    icon: Icons.notifications_outlined,
                    activeIcon: Icons.notifications_rounded,
                    label: 'Alertas',
                    isActive: _selectedIndex == 3,
                    badge: notifProvider.cantidadNoLeidas,
                    onTap: () => setState(() => _selectedIndex = 4),
                  );
                },
              ),
              _NavItem(
                icon: Icons.person_outline_rounded,
                activeIcon: Icons.person_rounded,
                label: 'Perfil',
                isActive: _selectedIndex == 4,
                onTap: () => setState(() => _selectedIndex = 5),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isActive,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive
              ? AppColors.primary.withOpacity(0.1)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              label: Text('$badge', style: const TextStyle(fontSize: 10)),
              isLabelVisible: badge > 0,
              backgroundColor: AppColors.error,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                color: isActive ? AppColors.primary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
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
    final reservasProvider = Provider.of<ReservasHotelProvider>(context);
    final nombreHuesped = authProvider.nombreHuesped;
    final reservas = reservasProvider.reservasActivas;

    // Cargar al entrar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (reservasProvider.reservas.isEmpty && !reservasProvider.isLoading) {
        reservasProvider.cargar();
      }
    });

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hola, ${nombreHuesped.split(' ').first}',
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bienvenido a tu estancia',
                        style: TextStyle(
                            fontSize: 15, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        nombreHuesped.isNotEmpty
                            ? nombreHuesped[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          sliver: SliverList(
            delegate: SliverChildListDelegate([
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Mis Reservas',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary),
                  ),
                  if (reservas.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${reservas.length}',
                        style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: AppColors.primary),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 16),

              if (reservasProvider.isLoading)
                const Center(child: CircularProgressIndicator())
              else if (reservas.isEmpty)
                const _EmptyReservaCard()
              else
                ...reservas.take(2).map((r) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _ReservaCardHome(reserva: r),
                    )),

              const SizedBox(height: 28),
              const Text(
                'Acceso rápido',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              const _QuickAccessGrid(),
              const SizedBox(height: 28),
              const Text(
                'Servicios del hotel',
                style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary),
              ),
              const SizedBox(height: 16),
              const _ServicesList(),
              const SizedBox(height: 24),
            ]),
          ),
        ),
      ],
    );
  }
}

class _ReservaCardHome extends StatelessWidget {
  final ReservaHotel reserva;
  const _ReservaCardHome({required this.reserva});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevated,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservaDetalleScreen(reserva: reserva),
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.hotel_rounded,
                      color: Colors.white, size: 28),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reserva.numeroReserva,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        reserva.tieneCheckIn
                            ? 'Habitación ${reserva.habitacionId} · Check-in ✓'
                            : 'Esperando check-in en recepción',
                        style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.8)),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.arrow_forward_ios,
                    color: Colors.white54, size: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EmptyReservaCard extends StatelessWidget {
  const _EmptyReservaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Icon(Icons.hotel_rounded,
              size: 56, color: AppColors.primary.withOpacity(0.4)),
          const SizedBox(height: 16),
          const Text(
            'No tienes reservas activas',
            style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary),
          ),
          const SizedBox(height: 8),
          Text(
            'Tus reservas aparecerán aquí una vez creadas por el hotel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RoomCard extends StatelessWidget {
  final dynamic habitacion;

  const _RoomCard({required this.habitacion});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.elevated,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) =>
                    HabitacionDetalleScreen(habitacion: habitacion),
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                // Room Icon
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.hotel_rounded,
                    color: Colors.white,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),

                // Room Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Habitacion ${habitacion.numeroHabitacion}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        habitacion.tipoHabitacion,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                    ],
                  ),
                ),

                // PIN Badge
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.vpn_key_rounded,
                        color: AppColors.gold,
                        size: 16,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        habitacion.pinAcceso ?? 'N/A',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ViewAllButton extends StatelessWidget {
  final int count;

  const _ViewAllButton({required this.count});

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const MisHabitacionesScreen(),
          ),
        );
      },
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Ver todas las habitaciones ($count)',
            style: TextStyle(
              color: AppColors.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
          const SizedBox(width: 4),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.primary,
            size: 14,
          ),
        ],
      ),
    );
  }
}

class _EmptyRoomCard extends StatelessWidget {
  const _EmptyRoomCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: AppColors.backgroundSecondary,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.divider),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.hotel_rounded,
              color: AppColors.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 16),
          const Text(
            'Sin habitaciones activas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Realiza tu check-in para ver tus habitaciones',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 14, color: AppColors.textSecondary),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/checkin'),
              child: const Text('Hacer Check-in'),
            ),
          ),
        ],
      ),
    );
  }
}

class _QuickAccessGrid extends StatelessWidget {
  const _QuickAccessGrid();

  @override
  Widget build(BuildContext context) {
    final items = [
      {
        'icon': Icons.room_service_outlined,
        'label': 'Room Service',
        'route': '/room-service',
      },
      {'icon': Icons.wifi_rounded, 'label': 'WiFi', 'route': '/wifi'},
      {
        'icon': Icons.local_parking_rounded,
        'label': 'Parking',
        'route': '/parking',
      },
      {
        'icon': Icons.support_agent_rounded,
        'label': 'Soporte',
        'route': '/support',
      },
    ];

    return Row(
      children: items
          .map(
            (item) => Expanded(
              child: Padding(
                padding: EdgeInsets.only(
                  right: items.indexOf(item) < items.length - 1 ? 12 : 0,
                ),
                child: _QuickAccessItem(
                  icon: item['icon'] as IconData,
                  label: item['label'] as String,
                  onTap: () {},
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _QuickAccessItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  const _QuickAccessItem({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: AppColors.backgroundSecondary,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primary, size: 24),
            const SizedBox(height: 8),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ServicesList extends StatelessWidget {
  const _ServicesList();

  @override
  Widget build(BuildContext context) {
    final services = [
      {
        'icon': Icons.spa_outlined,
        'title': 'Spa & Wellness',
        'subtitle': 'Relajacion total',
      },
      {
        'icon': Icons.restaurant_outlined,
        'title': 'Restaurante',
        'subtitle': 'Gastronomia local',
      },
      {
        'icon': Icons.pool_outlined,
        'title': 'Piscina',
        'subtitle': 'Abierta 7am - 10pm',
      },
      {
        'icon': Icons.fitness_center_outlined,
        'title': 'Gimnasio',
        'subtitle': '24 horas',
      },
    ];

    return Column(
      children: services
          .map(
            (service) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ServiceItem(
                icon: service['icon'] as IconData,
                title: service['title'] as String,
                subtitle: service['subtitle'] as String,
              ),
            ),
          )
          .toList(),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;

  const _ServiceItem({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.divider),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.arrow_forward_ios_rounded,
            color: AppColors.textTertiary,
            size: 16,
          ),
        ],
      ),
    );
  }
}

// Tab wrappers (unchanged logic)
class _ActividadesTab extends StatelessWidget {
  const _ActividadesTab();
  @override
  Widget build(BuildContext context) => const ActividadesScreen();
}

class _NotificacionesTab extends StatelessWidget {
  const _NotificacionesTab();
  @override
  Widget build(BuildContext context) => const NotificacionesScreen();
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab();
  @override
  Widget build(BuildContext context) => const PerfilScreen();
}


class _ReservasHotelTab extends StatelessWidget {
  const _ReservasHotelTab();
  @override
  Widget build(BuildContext context) => const MisReservasHotelScreen();
}

