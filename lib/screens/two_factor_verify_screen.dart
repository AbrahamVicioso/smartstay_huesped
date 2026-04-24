import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notificaciones_provider.dart';
import '../services/api/secure_storage_service.dart';

class TwoFactorVerifyScreen extends StatefulWidget {
  const TwoFactorVerifyScreen({super.key});

  @override
  State<TwoFactorVerifyScreen> createState() => _TwoFactorVerifyScreenState();
}

class _TwoFactorVerifyScreenState extends State<TwoFactorVerifyScreen> {
  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();

  bool _isResending = false;
  String? _errorMessage;

  static const Color _deepBlue = Color(0xFF003366);
  static const Color _slateBlue = Color(0xFF336699);
  static const Color _softGrey = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    super.dispose();
  }

  Future<void> _handleVerify() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      setState(() => _errorMessage = 'Ingresa los 6 dígitos del código');
      return;
    }

    setState(() => _errorMessage = null);

    final email =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    final success = await authProvider.verifyTwoFactor(email, code);

    if (!mounted) return;

    if (success) {
      final notifProvider =
          Provider.of<NotificacionesProvider>(context, listen: false);
      final storage = SecureStorageService();
      final token = await storage.getAccessToken();
      if (token != null) await notifProvider.startNtfy(token);
      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() {
        _errorMessage =
            authProvider.errorMessage ?? 'Código inválido o expirado';
      });
      _codeController.clear();
      _codeFocus.requestFocus();
      authProvider.clearError();
    }
  }

  Future<void> _handleResend() async {
    final email =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    setState(() => _isResending = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.sendTwoFactorCode(email);

    if (!mounted) return;
    setState(() => _isResending = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ok
            ? 'Código reenviado a $email'
            : 'Error al reenviar el código'),
        backgroundColor: ok ? _deepBlue : Colors.red,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final email =
        ModalRoute.of(context)?.settings.arguments as String? ?? '';
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _softGrey,
      body: Stack(
        children: [
          _buildBackground(),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 48),
                  _buildHeader(email),
                  const SizedBox(height: 40),
                  if (_errorMessage != null) ...[
                    _buildErrorCard(),
                    const SizedBox(height: 20),
                  ],
                  _buildCodeCard(authProvider),
                  const SizedBox(height: 24),
                  _buildResendButton(),
                  const SizedBox(height: 16),
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text(
                      'Volver al inicio de sesión',
                      style: TextStyle(color: _slateBlue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBackground() {
    return Stack(
      children: [
        Positioned(
          top: -80,
          right: -60,
          child: Container(
            width: 240,
            height: 240,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _deepBlue.withOpacity(0.15),
                _deepBlue.withOpacity(0),
              ]),
            ),
          ),
        ),
        Positioned(
          bottom: -100,
          left: -80,
          child: Container(
            width: 280,
            height: 280,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(colors: [
                _slateBlue.withOpacity(0.12),
                _slateBlue.withOpacity(0),
              ]),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(String email) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepBlue, _slateBlue],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: _deepBlue.withOpacity(0.3),
                blurRadius: 24,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: const Icon(
            Icons.shield_outlined,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 24),
        const Text(
          'Verificación en dos pasos',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.8,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 10),
        Text(
          'Ingresa el código de 6 dígitos enviado a\n$email',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 14,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.red.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              const Icon(Icons.error_outline_rounded,
                  color: Colors.red, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _errorMessage!,
                  style: const TextStyle(
                      color: Colors.red, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCodeCard(AuthProvider authProvider) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(28),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.75),
            borderRadius: BorderRadius.circular(28),
            border: Border.all(
                color: Colors.white.withOpacity(0.8), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: _deepBlue.withOpacity(0.08),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            children: [
              TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                autofocus: true,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                  letterSpacing: 12,
                ),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: '------',
                  hintStyle: TextStyle(
                    fontSize: 28,
                    color: _deepBlue.withOpacity(0.2),
                    letterSpacing: 12,
                  ),
                  filled: true,
                  fillColor: _softGrey,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide:
                        BorderSide(color: _deepBlue.withOpacity(0.1), width: 1),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _deepBlue, width: 2),
                  ),
                ),
                onChanged: (v) {
                  if (v.length == 6) _handleVerify();
                },
              ),
              const SizedBox(height: 28),
              _buildVerifyButton(authProvider),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVerifyButton(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepBlue, _slateBlue],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: authProvider.isLoading ? null : _handleVerify,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Text(
                    'Verificar código',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildResendButton() {
    return TextButton(
      onPressed: _isResending ? null : _handleResend,
      child: _isResending
          ? const SizedBox(
              height: 16,
              width: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text(
              '¿No recibiste el código? Reenviar',
              style: TextStyle(
                color: _slateBlue,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
    );
  }
}
