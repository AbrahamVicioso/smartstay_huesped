
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notificaciones_provider.dart';
import '../services/reservas_hotel_provider.dart';
import '../models/reserva_hotel.dart';
import 'actividades_screen.dart';
import 'perfil_screen.dart';
import 'mis_reservas_combinadas_screen.dart'; 
import 'reserva_detalle_screen.dart';

const Color _deepBlue  = Color(0xFF003366);
const Color _slateBlue = Color(0xFF336699);
const Color _softGrey  = Color(0xFFF8FAFC);
const Color _textPrimary   = Color(0xFF0F172A);
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
    final authProvider    = Provider.of<AuthProvider>(context, listen: false);
    final notifProvider   = Provider.of<NotificacionesProvider>(context, listen: false);
    final reservasProvider = Provider.of<ReservasHotelProvider>(context, listen: false);

    if (authProvider.usuario != null) {
      await notifProvider.cargarNotificaciones(authProvider.usuario!.id);
    }
    await reservasProvider.cargar();
  }

  void _onTabTapped(int index) {
    final reservasProvider =
        Provider.of<ReservasHotelProvider>(context, listen: false);
    
    if (index == 0 || index == 1) reservasProvider.recargar();
    setState(() => _selectedIndex = index);
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
          MisReservasCombinadas(),   
          _ExplorarTab(),            
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
              border: Border.all(color: Colors.white.withOpacity(0.8), width: 1.2),
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
                  label: 'Inicio',
                  isActive: _selectedIndex == 0,
                  onTap: () => _onTabTapped(0),
                ),
                _NavItem(
                  icon: Icons.receipt_long_outlined,
                  activeIcon: Icons.receipt_long_rounded,
                  label: 'Reservas',
                  isActive: _selectedIndex == 1,
                  onTap: () => _onTabTapped(1),
                ),
                _NavItem(
                  icon: Icons.explore_outlined,
                  activeIcon: Icons.explore_rounded,
                  label: 'Explorar',
                  isActive: _selectedIndex == 2,
                  onTap: () => _onTabTapped(2),
                ),
                Consumer<NotificacionesProvider>(
                  builder: (context, notif, _) => _NavItem(
                    icon: Icons.person_outline_rounded,
                    activeIcon: Icons.person_rounded,
                    label: 'Perfil',
                    isActive: _selectedIndex == 3,
                    badge: notif.cantidadNoLeidas,
                    onTap: () => _onTabTapped(3),
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
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          gradient: isActive
              ? const LinearGradient(colors: [_deepBlue, _slateBlue])
              : null,
          borderRadius: BorderRadius.circular(16),
          boxShadow: isActive
              ? [BoxShadow(color: _deepBlue.withOpacity(0.35), blurRadius: 12, offset: const Offset(0, 6))]
              : null,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Badge(
              label: Text('$badge', style: const TextStyle(fontSize: 10)),
              isLabelVisible: badge > 0,
              backgroundColor: Colors.red,
              child: Icon(
                isActive ? activeIcon : icon,
                color: isActive ? Colors.white : _textSecondary,
                size: 22,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : _textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _DashboardTab extends StatelessWidget {
  const _DashboardTab();

  @override
  Widget build(BuildContext context) {
    final authProvider     = Provider.of<AuthProvider>(context);
    final reservasProvider = Provider.of<ReservasHotelProvider>(context);
    final nombreHuesped    = authProvider.nombreHuesped;
    final reservas         = reservasProvider.reservasActivas;

    return CustomScrollView(
      physics: const BouncingScrollPhysics(),
      slivers: [
        
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
                          'Hola, ${nombreHuesped.split(' ').first} ',
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: _textPrimary,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Bienvenido a tu estancia',
                          style: TextStyle(fontSize: 14, color: _textSecondary),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(colors: [_deepBlue, _slateBlue]),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [BoxShadow(color: _deepBlue.withOpacity(0.3), blurRadius: 14, offset: const Offset(0, 6))],
                    ),
                    child: Center(
                      child: Text(
                        nombreHuesped.isNotEmpty ? nombreHuesped[0].toUpperCase() : 'U',
                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        
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

        
        if (reservas.length > 1) ...[
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 4, 20, 10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Otras reservas',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(color: _deepBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(10)),
                    child: Text('${reservas.length - 1}',
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: _deepBlue)),
                  ),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            sliver: SliverList(
              delegate: SliverChildListDelegate(
                reservas.skip(1).take(2).map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _ReservaCompactCard(reserva: r),
                )).toList(),
              ),
            ),
          ),
        ],

        
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 20, 20, 12),
            child: Text('Acceso rápido',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          ),
        ),
        const SliverToBoxAdapter(child: _BentoQuickAccess()),

        
        const SliverToBoxAdapter(
          child: Padding(
            padding: EdgeInsets.fromLTRB(20, 24, 20, 12),
            child: Text('Servicios del hotel',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _textPrimary)),
          ),
        ),
        const SliverToBoxAdapter(child: _ServicesList()),
        const SliverToBoxAdapter(child: SizedBox(height: 120)),
      ],
    );
  }
}


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
                  title: 'Solicitar\nServicio',
                  subtitle: 'A tu habitación',
                  color: _deepBlue,
                  tall: true,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Column(
                  children: [
                    _BentoCardSmall(
                      icon: Icons.cleaning_services_outlined,
                      title: 'Limpieza',
                      color: _slateBlue,
                      onTap: () {},
                    ),
                    const SizedBox(height: 12),
                    _BentoCardSmall(
                      icon: Icons.support_agent_rounded,
                      title: 'Soporte',
                      color: _gold,
                      onTap: () {},
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _BentoCardSmall(
                  icon: Icons.local_dining_outlined,
                  title: 'Menú',
                  color: _deepBlue,
                  onTap: () {},
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _BentoCardSmall(
                  icon: Icons.map_outlined,
                  title: 'Explorar',
                  color: _slateBlue,
                  onTap: () {},
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
  final String subtitle;
  final Color color;
  final bool tall;
  final VoidCallback onTap;

  const _BentoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
    this.tall = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: tall ? 180 : 100,
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color, color.withOpacity(0.75)],
          ),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: color.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 8))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: Colors.white.withOpacity(0.22), borderRadius: BorderRadius.circular(14)),
              child: Icon(icon, color: Colors.white, size: 24),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white, height: 1.1)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.white.withOpacity(0.75))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _BentoCardSmall extends StatelessWidget {
  final IconData icon;
  final String title;
  final Color color;
  final VoidCallback onTap;

  const _BentoCardSmall({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: _deepBlue.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: _deepBlue.withOpacity(0.04), blurRadius: 12, offset: const Offset(0, 4))],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(color: color.withOpacity(0.12), borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(title,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
            ),
          ],
        ),
      ),
    );
  }
}


class _ErrorCard extends StatelessWidget {
  final String error;
  const _ErrorCard({required this.error});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Column(children: [
        const Icon(Icons.error_outline, size: 36, color: Colors.red),
        const SizedBox(height: 12),
        const Text('Error al cargar reservas', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: _textPrimary)),
        const SizedBox(height: 6),
        Text(error, textAlign: TextAlign.center, style: const TextStyle(fontSize: 13, color: _textSecondary)),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Provider.of<ReservasHotelProvider>(context, listen: false).cargar(),
          icon: const Icon(Icons.refresh),
          label: const Text('Reintentar'),
          style: ElevatedButton.styleFrom(backgroundColor: _deepBlue, foregroundColor: Colors.white),
        ),
      ]),
    );
  }
}

class _LoadingCard extends StatelessWidget {
  const _LoadingCard();
  @override
  Widget build(BuildContext context) => Container(
    height: 200,
    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(28)),
    child: const Center(child: CircularProgressIndicator(color: _deepBlue)),
  );
}

class _EmptyReservaCard extends StatelessWidget {
  const _EmptyReservaCard();
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(28),
        border: Border.all(color: _deepBlue.withOpacity(0.06)),
      ),
      child: Column(children: [
        Container(
          width: 72, height: 72,
          decoration: BoxDecoration(color: _deepBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(24)),
          child: const Icon(Icons.hotel_rounded, size: 36, color: _deepBlue),
        ),
        const SizedBox(height: 16),
        const Text('No tienes reservas activas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: _textPrimary)),
        const SizedBox(height: 6),
        const Text('Tus reservas aparecerán aquí una vez\ncreadas por el hotel',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: _textSecondary, height: 1.5)),
      ]),
    );
  }
}

class _SmartKeyCard extends StatefulWidget {
  final ReservaHotel reserva;
  const _SmartKeyCard({required this.reserva});
  @override
  State<_SmartKeyCard> createState() => _SmartKeyCardState();
}

class _SmartKeyCardState extends State<_SmartKeyCard> with SingleTickerProviderStateMixin {
  late AnimationController _pulse;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);
    _anim  = Tween<double>(begin: 0.6, end: 1.0).animate(CurvedAnimation(parent: _pulse, curve: Curves.easeInOut));
  }

  @override
  void dispose() { _pulse.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReservaDetalleScreen(reserva: widget.reserva))),
      child: AnimatedBuilder(
        animation: _anim,
        builder: (context, child) => Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(color: _deepBlue.withOpacity(0.25 * _anim.value), blurRadius: 30 * _anim.value, spreadRadius: 2, offset: const Offset(0, 12)),
            ],
          ),
          child: child,
        ),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(begin: Alignment.topLeft, end: Alignment.bottomRight, colors: [_deepBlue, _slateBlue]),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
                child: const Row(mainAxisSize: MainAxisSize.min, children: [
                  Icon(Icons.verified_rounded, color: Colors.white, size: 14),
                  SizedBox(width: 4),
                  Text('Smart Key', style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
                ]),
              ),
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(14)),
                child: const Icon(Icons.vpn_key_rounded, color: _gold, size: 22),
              ),
            ]),
            const SizedBox(height: 28),
            Text(widget.reserva.numeroReserva,
                style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -0.5)),
            const SizedBox(height: 4),
            Text(
              widget.reserva.tieneCheckIn ? 'Check-in activo' : 'Esperando check-in en recepción',
              style: TextStyle(fontSize: 13, color: Colors.white.withOpacity(0.8)),
            ),
            const SizedBox(height: 16),
            Row(children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(color: Colors.white.withOpacity(0.15), borderRadius: BorderRadius.circular(12)),
                  child: Row(children: [
                    Icon(
                      widget.reserva.tieneCheckIn ? Icons.check_circle_rounded : Icons.access_time_rounded,
                      color: widget.reserva.tieneCheckIn ? Colors.greenAccent : _gold,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      widget.reserva.tieneCheckIn ? 'Check-in activo' : 'Pendiente',
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ]),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(color: Colors.white.withOpacity(0.18), borderRadius: BorderRadius.circular(12)),
                child: const Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
              ),
            ]),
          ]),
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
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => ReservaDetalleScreen(reserva: reserva))),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white, borderRadius: BorderRadius.circular(18),
          border: Border.all(color: _deepBlue.withOpacity(0.05)),
          boxShadow: [BoxShadow(color: _deepBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Row(children: [
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(color: _deepBlue.withOpacity(0.08), borderRadius: BorderRadius.circular(12)),
            child: const Icon(Icons.hotel_rounded, color: _deepBlue, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(reserva.numeroReserva,
                style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _textPrimary)),
            Text(reserva.tieneCheckIn ? 'Check-in activo' : 'Pendiente',
                style: const TextStyle(fontSize: 11, color: _textSecondary)),
          ])),
          const Icon(Icons.arrow_forward_ios_rounded, color: _textSecondary, size: 13),
        ]),
      ),
    );
  }
}


class _ServicesList extends StatelessWidget {
  const _ServicesList();
  @override
  Widget build(BuildContext context) {
    final services = [
      {'icon': Icons.spa_outlined,          'title': 'Spa & Wellness',  'subtitle': 'Reservar tratamiento'},
      {'icon': Icons.restaurant_outlined,   'title': 'Restaurante',     'subtitle': 'Ver menú y horarios'},
      {'icon': Icons.pool_outlined,         'title': 'Piscina',         'subtitle': 'Abierta 7am – 10pm'},
      {'icon': Icons.fitness_center_outlined,'title': 'Gimnasio',       'subtitle': '24 horas'},
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: services.map((s) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: _ServiceItem(icon: s['icon'] as IconData, title: s['title'] as String, subtitle: s['subtitle'] as String),
        )).toList(),
      ),
    );
  }
}

class _ServiceItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _ServiceItem({required this.icon, required this.title, required this.subtitle});
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white, borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _deepBlue.withOpacity(0.05)),
        boxShadow: [BoxShadow(color: _deepBlue.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(children: [
        Container(
          width: 44, height: 44,
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [_deepBlue.withOpacity(0.1), _slateBlue.withOpacity(0.08)]),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Icon(icon, color: _deepBlue, size: 20),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: _textPrimary)),
          Text(subtitle, style: const TextStyle(fontSize: 11, color: _textSecondary)),
        ])),
        const Icon(Icons.arrow_forward_ios_rounded, color: _textSecondary, size: 13),
      ]),
    );
  }
}


class _ExplorarTab extends StatelessWidget {
  const _ExplorarTab();
  @override
  Widget build(BuildContext context) => const ActividadesScreen();
}

class _PerfilTab extends StatelessWidget {
  const _PerfilTab();
  @override
  Widget build(BuildContext context) => const PerfilScreen();
}