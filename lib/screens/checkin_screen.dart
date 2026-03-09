import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/api/reservas_service.dart';
import '../theme/app_theme.dart';

class CheckinScreen extends StatefulWidget {
  const CheckinScreen({super.key});

  @override
  State<CheckinScreen> createState() => _CheckinScreenState();
}

class _CheckinScreenState extends State<CheckinScreen> {
  final _formKey = GlobalKey<FormState>();
  final _numeroReservaController = TextEditingController();
  final _documentoController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _checkInCompleted = false;

  final _reservasService = ReservasService();

  @override
  void dispose() {
    _numeroReservaController.dispose();
    _documentoController.dispose();
    super.dispose();
  }

  Future<void> _realizarCheckIn() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    // Variables para usar en catch block
    final numeroReserva = _numeroReservaController.text.trim();
    final documento = _documentoController.text.trim();

    try {
      // Validar que los campos no estén vacíos
      if (numeroReserva.isEmpty || documento.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor complete todos los campos';
          _isLoading = false;
        });
        return;
      }

      // Llamar a la API para validar la reserva
      final reserva = await _reservasService.validarReserva(
        numeroReserva,
        documento,
      );

      if (reserva != null) {
        // Reserva válida - completar check-in
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          
          // Actualizar el check-in en la base de datos
          final checkInExitoso = await _reservasService.realizarCheckIn(reserva.reservaId);
          
          if (!checkInExitoso) {
            setState(() {
              _errorMessage = 'Error al guardar el check-in en el servidor. Por favor intente de nuevo.';
              _isLoading = false;
            });
            return;
          }
          
          // Completar check-in y guardar estado
          await authProvider.completarCheckIn(reserva.reservaId);

          setState(() {
            _checkInCompleted = true;
            _isLoading = false;
          });
        }
      } else {
        // Reserva no válida
        setState(() {
          _errorMessage =
              'Reserva no encontrada. Verifique el número de reserva y documento.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error en check-in: $e');
      
      // Verificar si el error es que ya se hizo check-in
      if (e.toString().contains('CHECKIN_ALREADY_DONE')) {
        // El check-in ya fue realizado en el servidor, actualizar estado local
        setState(() {
          _isLoading = true;
        });
        
        try {
          // Buscar la reserva por número para obtener el ID
          final reservaExistente = await _reservasService.buscarReservaPorNumero(numeroReserva);
          if (reservaExistente != null && mounted) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            
            // Completar check-in y cargar habitaciones
            await authProvider.completarCheckIn(reservaExistente.reservaId);
            
            setState(() {
              _checkInCompleted = true;
              _isLoading = false;
            });
            return;
          }
        } catch (ex) {
          debugPrint('Error al completar check-in: $ex');
        }
        
        setState(() {
          _errorMessage = 'El check-in ya fue realizado para esta reserva. Ya puedes acceder a tu habitación.';
          _isLoading = false;
        });
        return;
      }
      
      setState(() {
        _errorMessage = 'Error al realizar el check-in. Intente de nuevo.';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    // Si ya hizo check-in, mostrar pantalla de éxito
    if (_checkInCompleted) {
      return _buildCheckInExitoso();
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Digital'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icono
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.verified_user,
                  size: 64,
                  color: AppTheme.primaryColor,
                ),
              ),

              const SizedBox(height: 24),

              // Título
              Text(
                'Bienvenido al Check-in Digital',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              // Descripción
              Text(
                'Ingrese los datos de su reserva para completar el check-in.',
                style: Theme.of(
                  context,
                ).textTheme.bodyMedium?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Información del usuario (prellenado)
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.person, color: AppTheme.primaryColor),
                              const SizedBox(width: 8),
                              Text(
                                'Datos del Huésped',
                                style: Theme.of(context).textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                          const Divider(),
                          _InfoRow(
                            label: 'Nombre',
                            value: authProvider.nombreHuesped,
                          ),
                          _InfoRow(
                            label: 'Email',
                            value:
                                authProvider.usuario?.email ?? 'No disponible',
                          ),
                          _InfoRow(
                            label: 'Teléfono',
                            value:
                                authProvider.usuario?.telefono ??
                                'No disponible',
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Campo número de reserva
              TextFormField(
                controller: _numeroReservaController,
                decoration: InputDecoration(
                  labelText: 'Número de Reserva',
                  hintText: 'Ej: R12345',
                  prefixIcon: Icon(Icons.confirmation_number),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el número de reserva';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Campo documento
              TextFormField(
                controller: _documentoController,
                decoration: InputDecoration(
                  labelText: 'Número de Documento',
                  hintText: 'Ej: 40212345678',
                  prefixIcon: Icon(Icons.badge),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.grey.shade50,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de documento';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              // Mensaje de error
              if (_errorMessage != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red.shade700),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red.shade700),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Botón de check-in
              ElevatedButton(
                onPressed: _isLoading ? null : _realizarCheckIn,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.login),
                          SizedBox(width: 8),
                          Text(
                            'Completar Check-in',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
              ),

              const SizedBox(height: 32),

              // Información adicional
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.blue.shade100),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.shade700,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          '¿Qué pasa después del check-in?',
                          style: Theme.of(context).textTheme.titleSmall
                              ?.copyWith(
                                color: Colors.blue.shade900,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    _InfoItem(
                      icon: Icons.hotel,
                      text: 'Se asignará su habitación automáticamente',
                    ),
                    const SizedBox(height: 8),
                    _InfoItem(
                      icon: Icons.pin,
                      text: 'Recibirá un PIN de acceso de 6 dígitos',
                    ),
                    const SizedBox(height: 8),
                    _InfoItem(
                      icon: Icons.lock_open,
                      text: 'Podrá abrir la puerta de su habitación',
                    ),
                    const SizedBox(height: 8),
                    _InfoItem(
                      icon: Icons.notifications_active,
                      text: 'Recibirá notificaciones de acceso a su habitación',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCheckInExitoso() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Check-in Completado'),
        backgroundColor: AppTheme.primaryColor,
        foregroundColor: Colors.white,
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icono de éxito
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle,
                  size: 80,
                  color: Colors.green.shade600,
                ),
              ),

              const SizedBox(height: 32),

              // Título
              Text(
                '¡Check-in Exitoso! 🎉',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.green.shade700,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              // Descripción
              Text(
                'Su check-in ha sido completado. Ahora puede acceder a su habitación.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppTheme.textSecondary),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Información de la habitación
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.habitacionesDetalladas.isEmpty) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          children: [
                            Icon(
                              Icons.hotel,
                              size: 48,
                              color: AppTheme.primaryColor,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Su habitación será asignada pronto',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  final habitacion = authProvider.habitacionesDetalladas.first;
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        children: [
                          Icon(
                            Icons.hotel,
                            size: 48,
                            color: AppTheme.primaryColor,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Habitación ${habitacion.numeroHabitacion}',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            habitacion.tipoHabitacion,
                            style: Theme.of(context).textTheme.bodyMedium
                                ?.copyWith(color: AppTheme.textSecondary),
                          ),
                          if (habitacion.pinAcceso != null) ...[
                            const SizedBox(height: 16),
                            Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: AppTheme.primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.pin, color: AppTheme.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    'PIN: ${habitacion.pinAcceso}',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18,
                                      color: AppTheme.primaryColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Botón volver al inicio
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Volver al inicio (el home screen)
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Ir al Inicio'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryColor,
                    foregroundColor: Colors.white,
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
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: TextStyle(
                color: AppTheme.textSecondary,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(value, style: TextStyle(fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

class _InfoItem extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoItem({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: Colors.blue.shade700),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(color: Colors.blue.shade900),
          ),
        ),
      ],
    );
  }
}
