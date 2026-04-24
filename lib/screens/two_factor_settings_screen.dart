import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

class TwoFactorSettingsScreen extends StatefulWidget {
  const TwoFactorSettingsScreen({super.key});

  @override
  State<TwoFactorSettingsScreen> createState() =>
      _TwoFactorSettingsScreenState();
}

class _TwoFactorSettingsScreenState extends State<TwoFactorSettingsScreen> {
  bool _isEnabled = false;
  bool _isLoading = true;
  bool _showEnableFlow = false;
  bool _codeSent = false;

  final _codeController = TextEditingController();
  final _codeFocus = FocusNode();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  static const Color _deepBlue = Color(0xFF003366);
  static const Color _slateBlue = Color(0xFF336699);
  static const Color _softGrey = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);

  @override
  void initState() {
    super.initState();
    _loadStatus();
  }

  @override
  void dispose() {
    _codeController.dispose();
    _codeFocus.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _loadStatus() async {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final enabled = await authProvider.getTwoFactorStatus();
    if (mounted) {
      setState(() {
        _isEnabled = enabled;
        _isLoading = false;
      });
    }
  }

  Future<void> _startEnableFlow() async {
    setState(() {
      _showEnableFlow = true;
      _isLoading = true;
    });

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.enableTwoFactor();

    if (!mounted) return;
    setState(() {
      _isLoading = false;
      _codeSent = ok;
    });

    if (!ok) {
      _showSnack(
          authProvider.errorMessage ?? 'Error al iniciar activación 2FA',
          isError: true);
    }
  }

  Future<void> _confirmEnable() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      _showSnack('Ingresa los 6 dígitos', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.confirmTwoFactor(code);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      setState(() {
        _isEnabled = true;
        _showEnableFlow = false;
        _codeSent = false;
      });
      _codeController.clear();
      _showSnack('Verificación en dos pasos activada');
    } else {
      _showSnack(authProvider.errorMessage ?? 'Código inválido', isError: true);
      _codeController.clear();
      _codeFocus.requestFocus();
    }
  }

  Future<void> _disableTwoFactor() async {
    final password = _passwordController.text.trim();
    if (password.isEmpty) {
      _showSnack('Ingresa tu contraseña', isError: true);
      return;
    }

    setState(() => _isLoading = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final ok = await authProvider.disableTwoFactor(password);

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (ok) {
      _passwordController.clear();
      setState(() => _isEnabled = false);
      _showSnack('Verificación en dos pasos desactivada');
    } else {
      _showSnack(
          authProvider.errorMessage ?? 'Contraseña incorrecta',
          isError: true);
    }
  }

  void _showSnack(String message, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.red : _deepBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showDisableDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Desactivar 2FA'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ingresa tu contraseña para desactivar la verificación en dos pasos.',
              style: TextStyle(fontSize: 14),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              decoration: InputDecoration(
                labelText: 'Contraseña',
                prefixIcon: const Icon(Icons.lock_outline),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined),
                  onPressed: () =>
                      setState(() => _obscurePassword = !_obscurePassword),
                ),
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _disableTwoFactor();
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Desactivar',
                style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        title: const Text('Verificación en dos pasos'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: _textPrimary,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildStatusCard(),
                  const SizedBox(height: 24),
                  if (!_isEnabled && !_showEnableFlow) _buildEnableButton(),
                  if (!_isEnabled && _showEnableFlow) _buildEnableFlow(),
                  if (_isEnabled) _buildDisableButton(),
                ],
              ),
            ),
    );
  }

  Widget _buildStatusCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
            boxShadow: [
              BoxShadow(
                color: _deepBlue.withOpacity(0.06),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: _isEnabled
                      ? Colors.green.withOpacity(0.15)
                      : Colors.orange.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(
                  _isEnabled
                      ? Icons.shield_rounded
                      : Icons.shield_outlined,
                  color: _isEnabled ? Colors.green : Colors.orange,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _isEnabled ? 'Activada' : 'Desactivada',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: _isEnabled ? Colors.green : Colors.orange,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _isEnabled
                          ? 'Tu cuenta está protegida con 2FA'
                          : 'Activa 2FA para mayor seguridad',
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSecondary,
                      ),
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

  Widget _buildEnableButton() {
    return _buildPrimaryButton(
      label: 'Activar verificación en dos pasos',
      icon: Icons.security_rounded,
      onTap: _startEnableFlow,
    );
  }

  Widget _buildEnableFlow() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.8),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: Colors.white.withOpacity(0.8)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Confirmar activación',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: _textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Hemos enviado un código a tu correo. Ingrésalo para activar 2FA.',
                style: TextStyle(fontSize: 13, color: _textSecondary),
              ),
              const SizedBox(height: 24),
              TextField(
                controller: _codeController,
                focusNode: _codeFocus,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: 6,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
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
                  if (v.length == 6) _confirmEnable();
                },
              ),
              const SizedBox(height: 24),
              _buildPrimaryButton(
                label: 'Confirmar',
                icon: Icons.check_circle_outline,
                onTap: _confirmEnable,
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _showEnableFlow = false;
                  _codeSent = false;
                }),
                child: const Text('Cancelar',
                    style: TextStyle(color: _textSecondary)),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDisableButton() {
    return Container(
      width: double.infinity,
      height: 54,
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.red.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: _showDisableDialog,
          borderRadius: BorderRadius.circular(16),
          child: const Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.no_encryption_outlined,
                    color: Colors.red, size: 20),
                SizedBox(width: 8),
                Text(
                  'Desactivar 2FA',
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPrimaryButton({
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
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
            color: _deepBlue.withOpacity(0.28),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Center(
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
