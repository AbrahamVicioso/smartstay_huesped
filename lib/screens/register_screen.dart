import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _numeroDocumentoController = TextEditingController();

  // ✅ CAMBIO AQUÍ
  int _tipoDocumentoId = 1;
  final List<Map<String, dynamic>> _tiposDocumento = [
    {'id': 1, 'nombre': 'Cédula'},
    {'id': 2, 'nombre': 'Pasaporte'},
    {'id': 3, 'nombre': 'Identificación Extranjera'},
    {'id': 4, 'nombre': 'RNC'},
    {'id': 5, 'nombre': 'Otro'},
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isCheckingDocument = false;

  // Paleta
  static const Color _deepBlue = Color(0xFF003366);
  static const Color _slateBlue = Color(0xFF336699);
  static const Color _softGrey = Color(0xFFF8FAFC);
  static const Color _textPrimary = Color(0xFF0F172A);
  static const Color _textSecondary = Color(0xFF64748B);
  static const Color _successGreen = Color(0xFF10B981);

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _numeroDocumentoController.dispose();
    super.dispose();
  }

  Future<bool> _checkDocumentExists() async {
    if (_numeroDocumentoController.text.trim().isEmpty) return false;

    setState(() => _isCheckingDocument = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final exists = await authProvider.documentoExiste(
      _numeroDocumentoController.text.trim(),
    );

    setState(() => _isCheckingDocument = false);
    return exists;
  }

  // ✅ CAMBIO AQUÍ
  Future<void> _handleRegister() async {
    if (!_acceptedTerms) {
      _showToast('Debe aceptar los términos y condiciones',
          icon: Icons.info_outline);
      return;
    }

    final documentExists = await _checkDocumentExists();
    if (!mounted) return;

    if (documentExists) {
      _showToast('Ya existe un huésped con ese número de documento',
          icon: Icons.warning_amber_rounded);
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        nombreCompleto: _nombreController.text.trim(),
        numeroDocumento: _numeroDocumentoController.text.trim(),
        tipoDocumentoId: _tipoDocumentoId,
      );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        final errorMessage =
            authProvider.errorMessage ?? 'Error al registrarse.';
        _showToast(errorMessage, icon: Icons.error_outline);
        authProvider.clearError();
      }
    }
  }

  void _showToast(String message, {required IconData icon}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
        backgroundColor: _deepBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Registro exitoso'),
        content: const Text('Ya puedes iniciar sesión'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pop(context);
            },
            child: const Text('OK'),
          )
        ],
      ),
    );
  }

  // UI
  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _softGrey,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _buildField(
                controller: _nombreController,
                label: 'Nombre',
                hint: 'Juan Perez',
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese nombre' : null,
              ),

              const SizedBox(height: 16),

              _buildDropdown(),

              const SizedBox(height: 16),

              _buildField(
                controller: _numeroDocumentoController,
                label: 'Documento',
                hint: '000000000',
                icon: Icons.badge,
                validator: (v) =>
                    v == null || v.isEmpty ? 'Ingrese documento' : null,
              ),

              const SizedBox(height: 16),

              _buildField(
                controller: _emailController,
                label: 'Email',
                hint: 'correo@email.com',
                icon: Icons.email,
                validator: (v) =>
                    v == null || !v.contains('@') ? 'Email inválido' : null,
              ),

              const SizedBox(height: 16),

              _buildField(
                controller: _passwordController,
                label: 'Contraseña',
                hint: '********',
                icon: Icons.lock,
                obscure: true,
                validator: (v) =>
                    v == null || v.length < 8 ? 'Min 8 caracteres' : null,
              ),

              const SizedBox(height: 16),

              _buildField(
                controller: _confirmPasswordController,
                label: 'Confirmar',
                hint: '********',
                icon: Icons.lock,
                obscure: true,
                validator: (v) =>
                    v != _passwordController.text ? 'No coinciden' : null,
              ),

              const SizedBox(height: 20),

              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) =>
                    setState(() => _acceptedTerms = v ?? false),
                title: const Text('Aceptar términos'),
              ),

              const SizedBox(height: 20),

              ElevatedButton(
                onPressed:
                    authProvider.isLoading ? null : _handleRegister,
                child: authProvider.isLoading
                    ? const CircularProgressIndicator()
                    : const Text('Registrarse'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  // ✅ NUEVO DROPDOWN
  Widget _buildDropdown() {
    return DropdownButtonFormField<int>(
      value: _tipoDocumentoId,
      decoration: const InputDecoration(
        labelText: 'Tipo de Documento',
        border: OutlineInputBorder(),
      ),
      items: _tiposDocumento
          .map((t) => DropdownMenuItem<int>(
                value: t['id'],
                child: Text(t['nombre']),
              ))
          .toList(),
      onChanged: (v) => setState(() => _tipoDocumentoId = v!),
    );
  }
}