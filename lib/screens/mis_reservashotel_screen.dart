import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../services/reservas_hotel_provider.dart';
import '../models/reserva_hotel.dart';
import '../theme/app_theme.dart';
import 'reserva_detalle_screen.dart';

class MisReservasHotelScreen extends StatefulWidget {
  const MisReservasHotelScreen({super.key});

  @override
  State<MisReservasHotelScreen> createState() =>
      _MisReservasHotelScreenState();
}

class _MisReservasHotelScreenState extends State<MisReservasHotelScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final ScrollController _historialScroll = ScrollController();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_onTabChanged);
    _historialScroll.addListener(_onHistorialScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) => _cargarActivas());
  }

  @override
  void dispose() {
    _tabController.dispose();
    _historialScroll.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging && _tabController.index == 1) {
      final provider = context.read<ReservasHotelProvider>();
      if (!provider.historialLoaded) {
        provider.cargarHistorial(reset: true);
      }
    }
  }

  void _onHistorialScroll() {
    if (_historialScroll.position.pixels >=
        _historialScroll.position.maxScrollExtent - 200) {
      context.read<ReservasHotelProvider>().cargarHistorial();
    }
  }

  Future<void> _cargarActivas() async {
    await context.read<ReservasHotelProvider>().cargar();
  }

  Future<void> _refrescarHistorial() async {
    await context.read<ReservasHotelProvider>().cargarHistorial(reset: true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Reservas'),
        centerTitle: true,
        automaticallyImplyLeading: false,
        actions: [
          Consumer<ReservasHotelProvider>(
            builder: (context, provider, _) {
              final loading = _tabController.index == 0
                  ? provider.isLoading
                  : provider.isLoadingHistorial;
              return IconButton(
                icon: loading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.refresh_rounded),
                onPressed: loading
                    ? null
                    : (_tabController.index == 0 ? _cargarActivas : _refrescarHistorial),
                tooltip: 'Refrescar',
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Activas'),
            Tab(text: 'Historial'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Activas tab
          Consumer<ReservasHotelProvider>(
            builder: (context, provider, _) {
              if (provider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildActivasList(provider.reservasActivas);
            },
          ),
          // Historial tab (paginated)
          Consumer<ReservasHotelProvider>(
            builder: (context, provider, _) {
              if (!provider.historialLoaded && provider.isLoadingHistorial) {
                return const Center(child: CircularProgressIndicator());
              }
              return _buildHistorialList(provider);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActivasList(List<ReservaHotel> lista) {
    if (lista.isEmpty) {
      return RefreshIndicator(
        onRefresh: _cargarActivas,
        child: ListView(children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.hotel_outlined, size: 80,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('No tienes reservas activas',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _cargarActivas,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: lista.length,
        itemBuilder: (context, index) =>
            _ReservaCard(reserva: lista[index], onVolver: _cargarActivas),
      ),
    );
  }

  Widget _buildHistorialList(ReservasHotelProvider provider) {
    if (provider.historial.isEmpty) {
      return RefreshIndicator(
        onRefresh: _refrescarHistorial,
        child: ListView(children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.5,
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.history, size: 80,
                      color: AppColors.textSecondary.withOpacity(0.4)),
                  const SizedBox(height: 16),
                  const Text('Sin reservas en historial',
                      style: TextStyle(fontSize: 16, color: AppColors.textSecondary)),
                ],
              ),
            ),
          ),
        ]),
      );
    }
    return RefreshIndicator(
      onRefresh: _refrescarHistorial,
      child: ListView.builder(
        controller: _historialScroll,
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: provider.historial.length + (provider.historialHasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index == provider.historial.length) {
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _ReservaCard(
            reserva: provider.historial[index],
            onVolver: _refrescarHistorial,
          );
        },
      ),
    );
  }
}

class _ReservaCard extends StatelessWidget {
  final ReservaHotel reserva;
  final Future<void> Function() onVolver;

  const _ReservaCard({required this.reserva, required this.onVolver});

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final color =
        reserva.tieneCheckIn ? AppColors.primary : AppColors.textSecondary;

    final int noches = reserva.diasRestantes < 0 ? 0 : reserva.diasRestantes;
    final bool estanciaFinalizada = reserva.diasRestantes < 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () async {
          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => ReservaDetalleScreen(reserva: reserva),
            ),
          );
          await onVolver();
        },
        child: Container(
          decoration: BoxDecoration(
            border: Border(left: BorderSide(color: color, width: 4)),
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.confirmation_number, color: color, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      reserva.numeroReserva,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: color,
                        fontSize: 15,
                      ),
                    ),
                  ),
                  _StatusBadge(reserva: reserva),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _DateInfo(
                      label: 'Check-in',
                      date: fmt.format(reserva.fechaCheckIn),
                      icon: Icons.login,
                    ),
                  ),
                  Expanded(
                    child: _DateInfo(
                      label: 'Check-out',
                      date: fmt.format(reserva.fechaCheckOut),
                      icon: Icons.logout,
                    ),
                  ),
                ],
              ),
              if (reserva.tieneCheckIn) ...[
                const SizedBox(height: 12),
                estanciaFinalizada
                    ? Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.grey.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.event_available,
                                size: 14,
                                color: AppColors.textSecondary),
                            SizedBox(width: 6),
                            Text(
                              'Estancia finalizada',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      )
                    : Row(
                        children: [
                          const Icon(Icons.nightlight_round,
                              size: 14,
                              color: AppColors.textSecondary),
                          const SizedBox(width: 4),
                          Text(
                            '$noches ${noches == 1 ? 'noche' : 'noches'} restantes',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ReservaHotel reserva;
  const _StatusBadge({required this.reserva});

  @override
  Widget build(BuildContext context) {
    final bool finalizada =
        reserva.tieneCheckIn && reserva.diasRestantes < 0;

    final String label;
    final Color color;

    if (finalizada) {
      label = 'Check-out ✓';
      color = Colors.grey;
    } else if (reserva.tieneCheckIn) {
      label = 'Check-in ✓';
      color = AppColors.primary;
    } else {
      label = 'Pendiente';
      color = Colors.orange;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _DateInfo extends StatelessWidget {
  final String label;
  final String date;
  final IconData icon;

  const _DateInfo({
    required this.label,
    required this.date,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 14, color: AppColors.textSecondary),
        const SizedBox(width: 4),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: const TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary)),
            Text(date,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600)),
          ],
        ),
      ],
    );
  }
}