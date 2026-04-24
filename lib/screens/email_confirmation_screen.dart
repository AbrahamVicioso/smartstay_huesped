import 'package:flutter/material.dart';

const Color _deepBlue = Color(0xFF003366);
const Color _slateBlue = Color(0xFF336699);

class EmailConfirmationScreen extends StatelessWidget {
  final String email;
  const EmailConfirmationScreen({super.key, required this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [_deepBlue, _slateBlue]),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.mark_email_unread_rounded,
                    color: Colors.white, size: 52),
              ),
              const SizedBox(height: 32),
              const Text(
                '¡Revisa tu correo!',
                style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF0F172A)),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Enviamos un enlace de confirmación a\n$email\n\nHaz clic en el enlace para activar tu cuenta.',
                style: const TextStyle(
                    fontSize: 15,
                    color: Color(0xFF64748B),
                    height: 1.6),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    // Volver al login eliminando todo el stack
                    Navigator.of(context)
                        .pushNamedAndRemoveUntil('/login', (_) => false);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text('Ir a iniciar sesión',
                      style: TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('← Volver al registro',
                    style: TextStyle(color: Color(0xFF64748B))),
              ),
            ],
          ),
        ),
      ),
    );
  }
}