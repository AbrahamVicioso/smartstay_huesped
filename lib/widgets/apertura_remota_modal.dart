import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../theme/app_theme.dart';

class AperturaRemotaModal extends StatefulWidget {
  final Reserva reserva;

  const AperturaRemotaModal({
    super.key,
    required this.reserva,
  });

  @override
  State<AperturaRemotaModal> createState() => _AperturaRemotaModalState();
}

class _AperturaRemotaModalState extends State<AperturaRemotaModal>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;

  bool _isUnlocking = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _rotationAnimation = Tween<double>(begin: 0.0, end: 0.5).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Curves.easeInOut,
      ),
    );

    _simularAperturaRemota();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _simularAperturaRemota() async {
    _controller.repeat(reverse: true);

    // Simular proceso de apertura
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isUnlocking = false;
        _isSuccess = true;
      });

      _controller.stop();
      await _controller.forward(from: 0);

      await Future.delayed(const Duration(milliseconds: 1000));

      if (mounted) {
        Navigator.of(context).pop();
        _mostrarMensajeExito();
      }
    }
  }

  void _mostrarMensajeExito() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.check_circle, color: Colors.white),
            const SizedBox(width: 12),
            Text('Habitación ${widget.reserva.numeroHabitacion} abierta remotamente'),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animación del candado
            AnimatedBuilder(
              animation: _controller,
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.rotate(
                    angle: _rotationAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: (_isSuccess ? Colors.green : Colors.blue)
                            .withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _isSuccess ? Icons.lock_open : Icons.wifi_lock,
                        size: 80,
                        color: _isSuccess ? Colors.green : Colors.blue,
                      ),
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: 32),

            // Indicador de progreso
            if (_isUnlocking)
              SizedBox(
                width: 40,
                height: 40,
                child: CircularProgressIndicator(
                  strokeWidth: 3,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    Colors.blue,
                  ),
                ),
              )
            else
              Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),

            const SizedBox(height: 24),

            // Texto
            Text(
              _isUnlocking
                  ? 'Abriendo Puerta...'
                  : _isSuccess
                      ? '¡Puerta Abierta!'
                      : 'Error',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),

            const SizedBox(height: 12),

            Text(
              _isUnlocking
                  ? 'Conectando con la cerradura de la habitación ${widget.reserva.numeroHabitacion}'
                  : _isSuccess
                      ? 'La puerta se ha desbloqueado exitosamente'
                      : 'No se pudo conectar con la cerradura',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (_isUnlocking) ...[
              const SizedBox(height: 24),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
