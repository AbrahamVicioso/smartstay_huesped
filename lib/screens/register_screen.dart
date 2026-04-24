import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import 'email_confirmation_screen.dart'; 

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
  final _nacionalidadController = TextEditingController();

  int _tipoDocumentoId = 1;
  static const _tiposDocumento = [
    {'id': 1, 'nombre': 'Pasaporte'},
    {'id': 2, 'nombre': 'Cédula de Identidad'},
    {'id': 3, 'nombre': 'Licencia de Conducir'},
  ];

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;

  static const Color _deepBlue = Color(0xFF003366);
  static const Color _softGrey = Color(0xFFF8FAFC);

  @override
  void dispose() {
    _nombreController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _numeroDocumentoController.dispose();
    _nacionalidadController.dispose();
    super.dispose();
  }

  bool _esCedulaValida(String cedula) {
    if (cedula.length != 11 || !RegExp(r'^\d{11}$').hasMatch(cedula)) {
      return false;
    }
    const pesos = [1, 2, 1, 2, 1, 2, 1, 2, 1, 2];
    int suma = 0;
    for (int i = 0; i < 10; i++) {
      int producto = int.parse(cedula[i]) * pesos[i];
      suma += producto >= 10 ? (producto ~/ 10) + (producto % 10) : producto;
    }
    final digitoVerificador = (10 - (suma % 10)) % 10;
    return int.parse(cedula[10]) == digitoVerificador;
  }

  String? _validarDocumento(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Ingrese el número de documento';
    }

    if (_tipoDocumentoId == 2) {
      final cedula = value.trim();
      if (cedula.length != 11 || !RegExp(r'^\d{11}$').hasMatch(cedula)) {
        return 'La cédula debe tener exactamente 11 dígitos numéricos';
      }
      if (!_esCedulaValida(cedula)) {
        return 'La cédula no es válida (dígito verificador incorrecto)';
      }
    }
    return null;
  }

  Future<void> _handleRegister() async {
    if (!_acceptedTerms) {
      _showSnack('Debe aceptar los términos y condiciones', isError: true);
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();

    final exists = await authProvider.documentoExiste(
      _numeroDocumentoController.text.trim(),
    );
    if (!mounted) return;

    if (exists) {
      _showSnack('Ya existe un huésped con ese número de documento', isError: true);
      return;
    }

    final success = await authProvider.register(
      _emailController.text.trim(),
      _passwordController.text,
      nombreCompleto: _nombreController.text.trim(),
      numeroDocumento: _numeroDocumentoController.text.trim(),
      tipoDocumentoId: _tipoDocumentoId,
      nacionalidad: _nacionalidadController.text.trim(),
    );

    if (!mounted) return;

    if (success) {
      _showSuccessDialog(); 
    } else {
      _showSnack(authProvider.errorMessage ?? 'Error al registrarse', isError: true);
      authProvider.clearError();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(color: Colors.white)),
      backgroundColor: isError ? Colors.red.shade700 : _deepBlue,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.all(16),
    ));
  }

  
  void _showSuccessDialog() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => EmailConfirmationScreen(
          email: _emailController.text.trim(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();

    return Scaffold(
      backgroundColor: _softGrey,
      appBar: AppBar(
        title: const Text('Crear cuenta'),
        backgroundColor: _deepBlue,
        foregroundColor: Colors.white,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [

              _buildField(
                controller: _nombreController,
                label: 'Nombre completo',
                hint: 'Juan Pérez',
                icon: Icons.person,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingrese su nombre' : null,
              ),
              const SizedBox(height: 16),

              DropdownButtonFormField<int>(
                value: _tipoDocumentoId,
                decoration: InputDecoration(
                  labelText: 'Tipo de documento',
                  prefixIcon: const Icon(Icons.badge),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                items: _tiposDocumento
                    .map((t) => DropdownMenuItem<int>(
                          value: t['id'] as int,
                          child: Text(t['nombre'] as String),
                        ))
                    .toList(),
                onChanged: (v) {
                  setState(() {
                    _tipoDocumentoId = v!;
                    _numeroDocumentoController.clear();
                  });
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _numeroDocumentoController,
                decoration: InputDecoration(
                  labelText: 'Número de documento',
                  prefixIcon: const Icon(Icons.credit_card),
                  hintText: _tipoDocumentoId == 2
                      ? '00112345678 (11 dígitos)'
                      : 'Número de documento',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                keyboardType: _tipoDocumentoId == 2
                    ? TextInputType.number
                    : TextInputType.text,
                inputFormatters: _tipoDocumentoId == 2
                    ? [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11)
                      ]
                    : null,
                validator: _validarDocumento,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _nacionalidadController,
                label: 'Nacionalidad',
                hint: 'Dominicana',
                icon: Icons.flag,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Ingrese su nacionalidad' : null,
              ),
              const SizedBox(height: 16),

              _buildField(
                controller: _emailController,
                label: 'Correo electrónico',
                hint: 'correo@email.com',
                icon: Icons.email,
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@')
                    ? 'Ingrese un email válido'
                    : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  labelText: 'Contraseña',
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(_obscurePassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) =>
                    v == null || v.length < 8 ? 'Mínimo 8 caracteres' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirmPassword,
                decoration: InputDecoration(
                  labelText: 'Confirmar contraseña',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    icon: Icon(_obscureConfirmPassword
                        ? Icons.visibility_off
                        : Icons.visibility),
                    onPressed: () => setState(() =>
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword),
                  ),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                validator: (v) => v != _passwordController.text
                    ? 'Las contraseñas no coinciden'
                    : null,
              ),
              const SizedBox(height: 20),

              CheckboxListTile(
                value: _acceptedTerms,
                onChanged: (v) => setState(() => _acceptedTerms = v ?? false),
                title: const Text('Acepto los términos y condiciones'),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
              ),
              const SizedBox(height: 20),

              SizedBox(
                height: 52,
                child: ElevatedButton(
                  onPressed: authProvider.isLoading ? null : _handleRegister,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _deepBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  child: authProvider.isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
                      : const Text('Crear cuenta',
                          style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(height: 16),
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
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      keyboardType: keyboardType,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}