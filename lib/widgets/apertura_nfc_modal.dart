import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../models/reserva.dart';
import '../theme/app_theme.dart';

class AperturaNFCModal extends StatefulWidget {
  final Reserva reserva;

  const AperturaNFCModal({
    super.key,
    required this.reserva,
  });

  @override
  State<AperturaNFCModal> createState() => _AperturaNFCModalState();
}

class _AperturaNFCModalState extends State<AperturaNFCModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _keyController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _keyRotationAnimation;
  late Animation<double> _keyScaleAnimation;

  bool _isScanning = true;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();

    // Animación de pulso para el ícono NFC
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(
        parent: _pulseController,
        curve: Curves.easeInOut,
      ),
    );

    // Animación de la llave
    _keyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _keyRotationAnimation = Tween<double>(begin: 0, end: math.pi / 4).animate(
      CurvedAnimation(
        parent: _keyController,
        curve: Curves.easeInOut,
      ),
    );

    _keyScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(
        parent: _keyController,
        curve: Curves.easeInOut,
      ),
    );

    // Simular escaneo NFC
    _simularEscaneoNFC();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _simularEscaneoNFC() async {
    // Esperar 3 segundos simulando escaneo
    await Future.delayed(const Duration(seconds: 3));

    if (mounted) {
      setState(() {
        _isScanning = false;
        _isSuccess = true;
      });

      // Animar la llave
      _pulseController.stop();
      await _keyController.forward();

      // Esperar un poco y cerrar
      await Future.delayed(const Duration(milliseconds: 1500));

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
            Text('Habitación ${widget.reserva.numeroHabitacion} abierta'),
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
            // Animación principal
            if (_isScanning) ...[
              // Ícono NFC pulsante
              AnimatedBuilder(
                animation: _pulseAnimation,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _pulseAnimation.value,
                    child: Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.nfc,
                        size: 80,
                        color: Colors.orange,
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              // Ondas de escaneo
              SizedBox(
                height: 60,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    _OndasNFC(controller: _pulseController, delay: 0.0),
                    _OndasNFC(controller: _pulseController, delay: 0.3),
                    _OndasNFC(controller: _pulseController, delay: 0.6),
                  ],
                ),
              ),
            ] else if (_isSuccess) ...[
              // Llave animada
              AnimatedBuilder(
                animation: _keyController,
                builder: (context, child) {
                  return Transform.scale(
                    scale: _keyScaleAnimation.value,
                    child: Transform.rotate(
                      angle: _keyRotationAnimation.value,
                      child: Container(
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.vpn_key,
                          size: 80,
                          color: Colors.green,
                        ),
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 32),

              Icon(
                Icons.check_circle,
                size: 60,
                color: Colors.green,
              ),
            ],

            const SizedBox(height: 24),

            // Texto
            Text(
              _isScanning
                  ? 'Escaneo NFC'
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
              _isScanning
                  ? 'Acerca el dispositivo al lector NFC de la puerta'
                  : _isSuccess
                      ? 'La habitación ${widget.reserva.numeroHabitacion} ha sido abierta exitosamente'
                      : 'No se pudo conectar con el lector',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),

            if (_isScanning) ...[
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

class _OndasNFC extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _OndasNFC({
    required this.controller,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, child) {
        final progress = ((controller.value + delay) % 1.0);
        return Opacity(
          opacity: 1.0 - progress,
          child: Container(
            width: 60 + (progress * 80),
            height: 60 + (progress * 80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.orange,
                width: 2,
              ),
            ),
          ),
        );
      },
    );
  }
}
