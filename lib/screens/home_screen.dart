import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notificaciones_provider.dart';
import 'actividades_screen.dart';
import 'notificaciones_screen.dart';
import 'perfil_screen.dart';
import 'mis_reservas_actividades_screen.dart';
import '../services/reservas_hotel_provider.dart';
import '../models/reserva_hotel.dart';
import 'reserva_detalle_screen.dart';
import 'mis_reservashotel_screen.dart';

// Paleta iOS 18
const Color _deepBlue = Color(0xFF003366);
const Color _slateBlue = Color(0xFF336699);
const Color _softGrey = Color(0xFFF8FAFC);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);
const Color _gold = Color(0xFFD4AF37);

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
    final notifProvider =
        Provider.of<NotificacionesProvider>(context, listen: false);
    final reservasProvider =
        Provider.of<ReservasHotelProvider>(context, listen: false);

    if (authProvider.usuario != null) {
      await notifProvider.cargarNotificaciones(authProvider.usuario!.id);
    }
    await reservasProvider.cargar();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      extendBody: true,
      body: IndexedStack(
        index: _selectedIndex,
        children: const [
          _DashboardTab(),
          MisReservasActividadesScreen(),
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
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.85),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.8),
                width: 1.2,
              ),
              boxShadow: [
                BoxShadow(
                  color: _deepBlue.withOpacity(0.1),
                  blurRadius: 24,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _NavItem(
                  icon: Icons.home_outlined,
                  activeIcon: Icons.home_rounded,
                  isActive: _selectedIndex == 0,
                  onTap: () => setState(() => _selectedIndex = 0),
                ),
                _NavItem(
                  icon: Icons.bookmark_outline_rounded,
                  activeIcon: Icons.bookmark_rounded,
                  isActive: _selectedIndex == 1,
                  onTap: () => setState(() => _selectedIndex = 1),
                ),
                _NavItem(
                  icon: Icons.calendar_today_outlined,
                  activeIcon: Icons.calendar_today_rounded,
                  isActive: _selectedIndex == 2,
                  onTap: () => setState(() => _selectedIndex = 2),
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  isActive: _selectedIndex == 3,
                  onTap: () => setState(() => _selectedIndex = 3),
                ),
                Consumer<NotificacionesProvider>(
                  builder: (context, notifProvider, child) {
                    return _NavItem(
                      icon: Icons.notifications_outlined,
                      activeIcon: Icons.notifications_rounded,
                      isActive: _selectedIndex == 4,
                      badge: notifProvider.cantidadNoLeidas,
                      onTap: () => setState(() => _selectedIndex = 4),
                    );
                  },
                ),
                _NavItem(
                  icon: Icons.person_outline_rounded,
                  activeIcon: Icons.person_rounded,
                  isActive: _selectedIndex == 5,
                  onTap: () => setState(() => _selectedIndex = 5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final IconData activeIcon;
  final bool isActive;
  final int badge;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.activeIcon,
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
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(
                  colors: [_deepBlue, _slateBlue],
                )
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [
                  BoxShadow(
                    color: _deepBlue.withOpacity(0.35),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Badge(
          label: Text('$badge', style: const TextStyle(fontSize: 10)),
          isLabelVisible: badge > 0,
          backgroundColor: Colors.red,
          child: Icon(
            isActive ? activeIcon : icon,
            color: isActive ? Colors.white : _textSecondary,
            size: 22,
          ),
        ),
      ),
    );
  }
}

// Dashboard Tab - BENTO GRID STYLE (sin controles IoT)
// lib/screens/home_screen.dart - Solo la parte del Dashboard que necesita cambios

class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final reservasProvider = Provider.of<ReservasHotelProvider>(context);
    final nombreHuesped = authProvider.nombreHuesped;
    final reservas = reservasProvider.reservasActivas;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        // Header (sin cambios)
        SliverToBoxAdapter(
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hola, ${nombreHuesped.split(' ').first}',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bienvenido a tu estancia',
                          style: TextStyle(
                            fontSize: 14,
                            color: _textSecondary,
                            fontWeight: FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_deepBlue, _slateBlue],
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: _deepBlue.withOpacity(0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        nombreHuesped.isNotEmpty
                            ? nombreHuesped[0].toUpperCase()
                            : 'U',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
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

        // Smart Key Card - CON MANEJO DE ERROR
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
            child: reservasProvider.isLoading
                ? const _LoadingCard()
                : reservasProvider.error != null
                    ? _ErrorCard(error: reservasProvider.error!)
                    : reservas.isEmpty
                        ? const _EmptyReservaCard()
                        : _SmartKeyCard(reserva: reservas.first),
          ),
        ),

        // Resto del código sin cambios...
        if (reservas.length > 1)
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Otras reservas',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: _deepBlue.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${reservas.length - 1}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _deepBlue,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        if (reservas.length > 1)
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                reservas
                    .skip(1)
                    .take(2)
                    .map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReservaCompactCard(reserva: r),
                        ))
                    .toList(),
              ),
            ),
          ),

        // Acceso rapido
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: const Text(
              'Acceso rápido',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: _BentoQuickAccess()),

        // Servicios del hotel
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: const Text(
              'Servicios del hotel',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ),
        const SliverToBoxAdapter(child: _ServicesList()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}

// NUEVO: Widget para mostrar errores
class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.red.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.error_outline,
                size: 36, color: Colors.red),
          ),
          const SizedBox(height: 16),
          const Text(
            'Error al cargar reservas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            error,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 13,
              color: _textSecondary,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              Provider.of<ReservasHotelProvider>(context, listen: false).cargar();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _deepBlue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
// Smart Key Card - Premium card con efecto glow
class _SmartKeyCard extends StatefulWidget {
  final ReservaHotel reserva;
  const _SmartKeyCard({required this.reserva});

  @override
  State<_SmartKeyCard> createState() => _SmartKeyCardState();
}

class _SmartKeyCardState extends State<_SmartKeyCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.6, end: 1.0)
        .animate(CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReservaDetalleScreen(reserva: widget.reserva),
        ),
      ),
      child: AnimatedBuilder(
        animation: _pulseAnimation,
        builder: (context, child) {
          return Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _deepBlue.withOpacity(0.25 * _pulseAnimation.value),
                  blurRadius: 30 * _pulseAnimation.value,
                  spreadRadius: 2,
                  offset: const Offset(0, 12),
                ),
                BoxShadow(
                  color: _slateBlue.withOpacity(0.15 * _pulseAnimation.value),
                  blurRadius: 60,
                  spreadRadius: 10 * _pulseAnimation.value,
                ),
              ],
            ),
            child: child,
          );
        },
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepBlue, _slateBlue],
            ),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.verified_rounded,
                            color: Colors.white, size: 14),
                        SizedBox(width: 4),
                        Text(
                          'Smart Key',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.vpn_key_rounded,
                        color: _gold, size: 22),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              Text(
                widget.reserva.numeroReserva,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                widget.reserva.tieneCheckIn
                    ? 'Habitación ${widget.reserva.habitacionId}'
                    : 'Esperando check-in en recepción',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.85),
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            widget.reserva.tieneCheckIn
                                ? Icons.check_circle_rounded
                                : Icons.access_time_rounded,
                            color: widget.reserva.tieneCheckIn
                                ? Colors.greenAccent
                                : _gold,
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            widget.reserva.tieneCheckIn
                                ? 'Check-in activo'
                                : 'Pendiente',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.18),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ReservaCompactCard extends StatelessWidget {
  final ReservaHotel reserva;
  const _ReservaCompactCard({required this.reserva});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => ReservaDetalleScreen(reserva: reserva),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _deepBlue.withOpacity(0.05)),
          boxShadow: [
            BoxShadow(
              color: _deepBlue.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: _deepBlue.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.hotel_rounded, color: _deepBlue, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    reserva.numeroReserva,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: _textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    reserva.tieneCheckIn
                        ? 'Habitación ${reserva.habitacionId}'
                        : 'Check-in pendiente',
                    style: const TextStyle(
                        fontSize: 12, color: _textSecondary),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: _textSecondary, size: 14),
          ],
        ),
      ),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _deepBlue),
      ),
    );
  }
}

class _EmptyReservaCard extends StatelessWidget {
  const _EmptyReservaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _deepBlue.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _deepBlue.withOpacity(0.08),
              borderRadius: BorderRadius.circular(24),
            ),
            child: const Icon(Icons.hotel_rounded,
                size: 36, color: _deepBlue),
          ),
          const SizedBox(height: 16),
          const Text(
            'No tienes reservas activas',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: _textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Tus reservas aparecerán aquí una vez\ncreadas por el hotel',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: _textSecondary,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

// Bento Grid 2x2 acceso rapido
class _BentoQuickAccess extends StatelessWidget {
  const _BentoQuickAccess();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: _BentoCard(
                  icon: Icons.room_service_outlined,
                  title: 'Room\nService',
                  color: _deepBlue,
                  tall: true,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: const [
                    _BentoCardSmall(
                      icon: Icons.wifi_rounded,
                      title: 'WiFi',
                      color: _slateBlue,
                    ),
                    SizedBox(height: 12),
                    _BentoCardSmall(
                      icon: Icons.local_parking_rounded,
                      title: 'Parking',
                      color: _gold,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: const [
              Expanded(
                child: _BentoCardSmall(
                  icon: Icons.support_agent_rounded,
                  title: 'Soporte',
                  color: _deepBlue,
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: _BentoCardSmall(
                  icon: Icons.map_outlined,
                  title: 'Explorar',
                  color: _slateBlue,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BentoCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final bool tall;

  const _BentoCard({
    required this.icon,
    required this.title,
    required this.color,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: tall ? 180 : 100,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [color, color.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: Colors.white, size: 24),
          ),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.1,
            ),
          ),
        ],
      ),
    );
  }
}

class _BentoCardSmall extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;

  const _BentoCardSmall({
    required this.icon,
    required this.title,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _deepBlue.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _textPrimary,
              ),
            ),
          ),
        ],
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
        'subtitle': 'Relajación total',
      },
      {
        'icon': Icons.restaurant_outlined,
        'title': 'Restaurante',
        'subtitle': 'Gastronomía local',
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

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: services
            .map((s) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ServiceItem(
                    icon: s['icon'] as IconData,
                    title: s['title'] as String,
                    subtitle: s['subtitle'] as String,
                  ),
                ))
            .toList(),
      ),
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _deepBlue.withOpacity(0.05)),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  _deepBlue.withOpacity(0.1),
                  _slateBlue.withOpacity(0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: _deepBlue, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: _textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: _textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const Icon(
            Icons.arrow_forward_ios_rounded,
            color: _textSecondary,
            size: 14,
          ),
        ],
      ),
    );
  }
}

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