import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class HotelInfoScreen extends StatelessWidget {
  const HotelInfoScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Información del Hotel'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Hotel Header
            Card(
              child: Column(
                children: [
                  Container(
                    height: 150,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor,
                      borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(16),
                      ),
                    ),
                    child: const Center(
                      child: Icon(Icons.hotel, size: 64, color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Text(
                          'Hotel SmartStay',
                          style: Theme.of(context).textTheme.headlineSmall
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const Icon(
                              Icons.star,
                              color: Colors.amber,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '5 Estrellas',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Horarios
            Text('🕐 Horarios', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              Icons.restaurant,
              'Restaurante',
              'Desayuno: 7:00 AM - 10:00 AM\nAlmuerzo: 12:00 PM - 3:00 PM\nCena: 7:00 PM - 10:00 PM',
            ),
            _buildInfoCard(
              context,
              Icons.pool,
              'Piscina',
              'Abierta las 24 horas',
            ),
            _buildInfoCard(
              context,
              Icons.fitness_center,
              'Gimnasio',
              'Abierto 24 horas',
            ),
            _buildInfoCard(context, Icons.spa, 'Spa', '10:00 AM - 8:00 PM'),
            const SizedBox(height: 24),

            // Servicios
            Text(
              '🛎️ Servicios',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 12),
            _buildServiceList(context),
            const SizedBox(height: 24),

            // Políticas
            Text('📋 Políticas', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              Icons.login,
              'Check-in',
              'A partir de las 3:00 PM',
            ),
            _buildInfoCard(
              context,
              Icons.logout,
              'Check-out',
              'Hasta las 12:00 PM',
            ),
            _buildInfoCard(
              context,
              Icons.smoke_free,
              'Política de Fumadores',
              'El hotel es 100% libre de humo. Hay áreas designadas para fumar.',
            ),
            _buildInfoCard(
              context,
              Icons.pets,
              'Mascotas',
              'No se permiten mascotas.',
            ),
            const SizedBox(height: 24),

            // Contacto
            Text('📞 Contacto', style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: 12),
            _buildInfoCard(
              context,
              Icons.phone,
              'Teléfono',
              '+1 (809) 555-0100',
            ),
            _buildInfoCard(context, Icons.email, 'Email', 'info@smartstay.com'),
            _buildInfoCard(
              context,
              Icons.location_on,
              'Dirección',
              'Avenida Principal 123, Santo Domingo,\nRepública Dominicana',
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String content,
  ) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppTheme.primaryColor),
        ),
        title: Text(title),
        subtitle: Text(content),
      ),
    );
  }

  Widget _buildServiceList(BuildContext context) {
    final services = [
      {'icon': Icons.wifi, 'name': 'WiFi Gratis'},
      {'icon': Icons.room_service, 'name': 'Room Service'},
      {'icon': Icons.local_parking, 'name': 'Estacionamiento'},
      {'icon': Icons.security, 'name': 'Seguridad 24/7'},
      {'icon': Icons.accessibility, 'name': 'Accesibilidad'},
      {'icon': Icons.airport_shuttle, 'name': 'Traslado'},
      {'icon': Icons.local_laundry_service, 'name': 'Lavandería'},
      {'icon': Icons.business_center, 'name': 'Centro de Negocios'},
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 3,
        crossAxisSpacing: 8,
        mainAxisSpacing: 8,
      ),
      itemCount: services.length,
      itemBuilder: (context, index) {
        final service = services[index];
        return Card(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                service['icon'] as IconData,
                color: AppTheme.primaryColor,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                service['name'] as String,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        );
      },
    );
  }
}
