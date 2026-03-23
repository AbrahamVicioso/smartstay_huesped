import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api/reservas_service.dart';
import '../theme/app_theme.dart';

class CheckInCheckOutScreen extends StatefulWidget {
  const CheckInCheckOutScreen({super.key});

  @override
  State<CheckInCheckOutScreen> createState() => _CheckInCheckOutScreenState();
}

class _CheckInCheckOutScreenState extends State<CheckInCheckOutScreen> {
  int _selectedIndex = 0;
  bool _isLoading = false;
  String? _message;

  final _reservasService = ReservasService();

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final habitaciones = authProvider.habitacionesDetalladas;
    
    // Obtener la reserva actual (si hay check-in realizado)
    final reservaActual = authProvider.reservaActual;
    final habitacionActual = habitaciones.isNotEmpty ? habitaciones.first : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in / Check-out'),
        centerTitle: true,
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Tab selector
          Container(
            margin: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Expanded(
                  child: _buildTab(0, 'Check-in', Icons.login),
                ),
                Expanded(
                  child: _buildTab(1, 'Check-out', Icons.logout),
                ),
              ],
            ),
          ),

          // Content
          Expanded(
            child: _selectedIndex == 0 
                ? _buildCheckInContent(authProvider, habitacionActual) 
                : _buildCheckOutContent(authProvider, habitacionActual, reservaActual),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(int index, String label, IconData icon) {
    final isSelected = _selectedIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _selectedIndex = index),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : AppTheme.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : AppTheme.textSecondary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCheckInContent(AuthProvider authProvider, dynamic habitacion) {
    final hasCheckIn = authProvider.hasCheckedIn;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: hasCheckIn ? Colors.green.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      hasCheckIn ? Icons.check_circle : Icons.login,
                      size: 48,
                      color: hasCheckIn ? Colors.green : Colors.orange,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    hasCheckIn ? 'Check-in Completado' : 'Check-in Digital',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasCheckIn 
                        ? 'Ya completaste tu check-in. Puedes acceder a tu habitación.'
                        : 'Completa tu check-in para acceder a tu habitación',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          // Información del huésped
          Card(
            child: ListTile(
              leading: const Icon(Icons.person, color: AppTheme.primaryColor),
              title: const Text('Huésped'),
              subtitle: Text(authProvider.nombreHuesped),
            ),
          ),
          
          // Información de la habitación (si hay check-in)
          if (hasCheckIn && habitacion != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.hotel, color: AppTheme.primaryColor),
                title: const Text('Habitación'),
                subtitle: Text(habitacion.numeroHabitacion ?? 'Por asignar'),
                trailing: const Icon(Icons.check_circle, color: Colors.green),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.pin, color: AppTheme.primaryColor),
                title: const Text('PIN de Acceso'),
                subtitle: Text(habitacion.pinAcceso ?? 'N/A'),
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          if (!hasCheckIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, '/checkin');
                },
                icon: const Icon(Icons.login),
                label: const Text('Ir a Check-in'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Generar QR de acceso
                },
                icon: const Icon(Icons.qr_code_scanner),
                label: const Text('Generar QR de Acceso'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCheckOutContent(AuthProvider authProvider, dynamic habitacion, dynamic reserva) {
    final hasCheckIn = authProvider.hasCheckedIn;
    final isLoading = _isLoading;
    final message = _message;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: hasCheckIn ? Colors.orange.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.logout,
                      size: 48,
                      color: hasCheckIn ? Colors.orange : Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Check-out Digital',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    hasCheckIn 
                        ? 'Programa tu salida'
                        : 'Debes completar el check-in primero',
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          
          if (hasCheckIn && habitacion != null) ...[
            Card(
              child: ListTile(
                leading: const Icon(Icons.hotel, color: AppTheme.primaryColor),
                title: const Text('Tu habitación'),
                subtitle: Text(habitacion.numeroHabitacion ?? 'Sin asignar'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.schedule, color: Colors.orange),
                title: const Text('Hora de Check-out'),
                subtitle: const Text('12:00 PM'),
              ),
            ),
            Card(
              child: ListTile(
                leading: const Icon(Icons.receipt_long, color: Colors.green),
                title: const Text('Estado de cuenta'),
                subtitle: const Text('Consultar en recepción'),
              ),
            ),
          ],
          
          // Mensaje de error o éxito
          if (message != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: message.contains('éxito') ? Colors.green.shade50 : Colors.red.shade50,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: message.contains('éxito') ? Colors.green.shade200 : Colors.red.shade200),
              ),
              child: Row(
                children: [
                  Icon(
                    message.contains('éxito') ? Icons.check_circle : Icons.error,
                    color: message.contains('éxito') ? Colors.green : Colors.red,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(
                        color: message.contains('éxito') ? Colors.green.shade700 : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          
          const SizedBox(height: 24),
          
          if (!hasCheckIn)
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: null,
                icon: const Icon(Icons.logout),
                label: const Text('Debes hacer Check-in primero'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.grey,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            )
          else
            Column(
              children: [
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : () => _realizarCheckOut(reserva.reservaId),
                    icon: isLoading 
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.logout),
                    label: Text(isLoading ? 'Procesando...' : 'Confirmar Check-out'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      // Extender estadía
                    },
                    icon: const Icon(Icons.extension),
                    label: const Text('Extender Estadía'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Future<void> _realizarCheckOut(int reservaId) async {
    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      final success = await _reservasService.realizarCheckOut(reservaId);
      
      if (success) {
        setState(() {
          _message = '¡Check-out realizado con éxito! Gracias por hospedarse con nosotros.';
        });
        
        // Opcional: limpiar el estado de check-in
        // final authProvider = Provider.of<AuthProvider>(context, listen: false);
        // await authProvider.resetCheckIn();
      } else {
        setState(() {
          _message = 'Error al realizar el check-out. Por favor intente de nuevo.';
        });
      }
    } catch (e) {
      setState(() {
        _message = 'Error al realizar el check-out: ${e.toString()}';
      });
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}
