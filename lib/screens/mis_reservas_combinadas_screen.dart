import 'package:flutter/material.dart';
import 'mis_reservashotel_screen.dart';
import 'mis_reservas_actividades_screen.dart';

const Color _deepBlue = Color(0xFF003366);
const Color _slateBlue = Color(0xFF336699);
const Color _bg = Color(0xFFF8FAFC);
const Color _textSecondary = Color(0xFF64748B);

class MisReservasCombinadas extends StatelessWidget {
  const MisReservasCombinadas({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: _bg,
        appBar: AppBar(
          title: const Text(
            'Mis Reservas',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          centerTitle: true,
          elevation: 0,
          backgroundColor: _bg,
          foregroundColor: Colors.black,
          automaticallyImplyLeading: false,
        ),
        body: Column(
          children: [
            const SizedBox(height: 12),

            
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: _deepBlue.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: TabBar(
                indicator: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [_deepBlue, _slateBlue],
                  ),
                ),
                labelColor: Colors.white,
                unselectedLabelColor: _textSecondary,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
                tabs: const [
                  Tab(
                    icon: Icon(Icons.hotel_rounded),
                    text: 'Hotel',
                  ),
                  Tab(
                    icon: Icon(Icons.local_activity_rounded),
                    text: 'Actividades',
                  ),
                ],
              ),
            ),

            const SizedBox(height: 12),

            
            Expanded(
              child: TabBarView(
                children: [
                  _HotelReservasBody(),
                  MisReservasActividadesScreen(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HotelReservasBody extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    
    
    
    return const MisReservasHotelScreen();
  }
}