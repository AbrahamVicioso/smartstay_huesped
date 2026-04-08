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

    final numeroReserva = _numeroReservaController.text.trim();
    final documento = _documentoController.text.trim();

    try {
      if (numeroReserva.isEmpty || documento.isEmpty) {
        setState(() {
          _errorMessage = 'Por favor complete todos los campos';
          _isLoading = false;
        });
        return;
      }

      final reserva = await _reservasService.validarReserva(
        numeroReserva,
        documento,
      );

      if (reserva != null) {
        if (mounted) {
          final authProvider = Provider.of<AuthProvider>(
            context,
            listen: false,
          );
          
          final telefono = authProvider.usuario?.telefono ?? '';
          
          final checkInExitoso = await _reservasService.realizarCheckIn(
            reserva.reservaId,
            telefono: telefono,
          );
          
          if (!checkInExitoso) {
            setState(() {
              _errorMessage = 'Error al guardar el check-in. Intente de nuevo.';
              _isLoading = false;
            });
            return;
          }
          
          await authProvider.completarCheckIn(reserva.reservaId);

          setState(() {
            _checkInCompleted = true;
            _isLoading = false;
          });
        }
      } else {
        setState(() {
          _errorMessage = 'Reserva no encontrada. Verifique los datos.';
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint('Error en check-in: $e');
      
      if (e.toString().contains('CHECKIN_ALREADY_DONE')) {
        setState(() {
          _isLoading = true;
        });
        
        try {
          final reservaExistente = await _reservasService.buscarReservaPorNumero(numeroReserva);
          if (reservaExistente != null && mounted) {
            final authProvider = Provider.of<AuthProvider>(
              context,
              listen: false,
            );
            
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
          _errorMessage = 'El check-in ya fue realizado. Ya puedes acceder a tu habitación.';
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
    if (_checkInCompleted) {
      return _buildCheckInExitoso();
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Check-in Digital'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Hero section
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.login_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 24),

              Text(
                'Bienvenido',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 8),

              Text(
                'Ingrese los datos de su reserva para completar el check-in.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Guest info card
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
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
                            const Icon(Icons.person, color: AppColors.primary, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              'Datos del Huésped',
                              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _buildInfoRow('Nombre', authProvider.nombreHuesped),
                        _buildInfoRow('Email', authProvider.usuario?.email ?? 'No disponible'),
                        _buildInfoRow('Teléfono', authProvider.usuario?.telefono ?? 'No disponible'),
                      ],
                    ),
                  );
                },
              ),

              const SizedBox(height: 24),

              // Form fields
              TextFormField(
                controller: _numeroReservaController,
                decoration: InputDecoration(
                  labelText: 'Número de Reserva',
                  hintText: 'Ej: R12345',
                  prefixIcon: const Icon(Icons.confirmation_number_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese el número de reserva';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 16),

              TextFormField(
                controller: _documentoController,
                decoration: InputDecoration(
                  labelText: 'Número de Documento',
                  hintText: 'Ej: 40212345678',
                  prefixIcon: const Icon(Icons.badge_outlined),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: AppColors.background,
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Por favor ingrese su número de documento';
                  }
                  return null;
                },
              ),

              // Error message
              if (_errorMessage != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: AppColors.error, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 32),

              // Primary button
              SizedBox(
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _realizarCheckIn,
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Completar Check-in',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),

              const SizedBox(height: 32),

              // Info section
              Container(
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
                        Icon(Icons.info_outline, color: AppColors.primary, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          '¿Qué pasa después?',
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _buildCheckItem(Icons.hotel, 'Se asignará su habitación automáticamente'),
                    _buildCheckItem(Icons.pin, 'Recibirá un PIN de acceso de 6 dígitos'),
                    _buildCheckItem(Icons.lock_open, 'Podrá abrir la puerta de su habitación'),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 80,
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckItem(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.primary),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckInExitoso() {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Success icon
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle,
                  size: 80,
                  color: AppColors.primary,
                ),
              ),

              const SizedBox(height: 32),

              Text(
                '¡Check-in Exitoso!',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 16),

              Text(
                'Su check-in ha sido completado. Ahora puede acceder a su habitación.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: AppColors.textSecondary,
                ),
                textAlign: TextAlign.center,
              ),

              const SizedBox(height: 32),

              // Room info
              Consumer<AuthProvider>(
                builder: (context, authProvider, child) {
                  if (authProvider.habitacionesDetalladas.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: AppColors.backgroundSecondary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Column(
                        children: [
                          const Icon(
                            Icons.hotel,
                            size: 48,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Su habitación será asignada pronto',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                      ),
                    );
                  }

                  final habitacion = authProvider.habitacionesDetalladas.first;
                  return Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: AppColors.backgroundSecondary,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      children: [
                        const Icon(
                          Icons.hotel,
                          size: 48,
                          color: AppColors.primary,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Habitación ${habitacion.numeroHabitacion}',
                          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        Text(
                          habitacion.tipoHabitacion,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                          ),
                        ),
                        if (habitacion.pinAcceso != null) ...[
                          const SizedBox(height: 16),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.pin, color: AppColors.primary, size: 20),
                                const SizedBox(width: 8),
                                Text(
                                  'PIN: ${habitacion.pinAcceso}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.of(context).popUntil((route) => route.isFirst);
                  },
                  icon: const Icon(Icons.home),
                  label: const Text('Ir al Inicio'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
