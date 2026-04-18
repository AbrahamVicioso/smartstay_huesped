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
  String _tipoDocumento = 'Cedula';
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedTerms = false;
  bool _isCheckingDocument = false;

  final List<String> _tiposDocumento = [
    'Cedula',
    'Pasaporte',
    'Identificación Extranjera',
    'RNC',
    'Otro',
  ];

  // Paleta iOS 18
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

  // LOGICA INTACTA
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

  Future<void> _handleRegister() async {
    if (!_acceptedTerms) {
      _showToast('Debe aceptar los terminos y condiciones',
          icon: Icons.info_outline);
      return;
    }

    final documentExists = await _checkDocumentExists();
    if (!mounted) return;

    if (documentExists) {
      _showToast(
        'Ya existe un huesped registrado con ese numero de documento',
        icon: Icons.warning_amber_rounded,
      );
      return;
    }

    if (_formKey.currentState!.validate()) {
      final authProvider = Provider.of<AuthProvider>(context, listen: false);

      final success = await authProvider.register(
        _emailController.text.trim(),
        _passwordController.text,
        nombreCompleto: _nombreController.text.trim().isNotEmpty
            ? _nombreController.text.trim()
            : null,
        tipoDocumento: _tipoDocumento,
        numeroDocumento: _numeroDocumentoController.text.trim().isNotEmpty
            ? _numeroDocumentoController.text.trim()
            : '',
      );

      if (!mounted) return;

      if (success) {
        _showSuccessDialog();
      } else {
        final errorMessage = authProvider.errorMessage ??
            'Error al registrarse. Intente nuevamente.';
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
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: _deepBlue,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        elevation: 8,
      ),
    );
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) => BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            padding: const EdgeInsets.all(28),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: _deepBlue.withOpacity(0.15),
                  blurRadius: 40,
                  offset: const Offset(0, 20),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: _successGreen.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: const BoxDecoration(
                        color: _successGreen,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.check_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Registro Exitoso',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: _textPrimary,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Su cuenta ha sido creada exitosamente.\nAhora puede iniciar sesion.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _textSecondary,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 28),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
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
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop();
                        },
                        child: const Center(
                          child: Text(
                            'Ir a Iniciar Sesion',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      backgroundColor: _softGrey,
      body: Stack(
        children: [
          // Fondo decorativo
          Positioned(
            top: -120,
            right: -100,
            child: Container(
              width: 320,
              height: 320,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    _deepBlue.withOpacity(0.12),
                    _deepBlue.withOpacity(0.0),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _buildAppBar(),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 32),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildGlassCard(
                            icon: Icons.person_outline_rounded,
                            title: 'Informacion Personal',
                            subtitle: 'Datos basicos del huesped',
                            child: _buildField(
                              controller: _nombreController,
                              label: 'Nombre Completo',
                              hint: 'Ej: Juan Perez',
                              icon: Icons.badge_outlined,
                              validator: (v) => v == null || v.trim().isEmpty
                                  ? 'Ingrese su nombre completo'
                                  : null,
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGlassCard(
                            icon: Icons.credit_card_rounded,
                            title: 'Documento de Identidad',
                            subtitle: 'Tipo y numero de identificacion',
                            child: Column(
                              children: [
                                _buildDropdown(),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _numeroDocumentoController,
                                  label: 'Numero de Documento',
                                  hint: 'Ingrese su numero',
                                  icon: Icons.numbers_rounded,
                                  suffix: _isCheckingDocument
                                      ? const Padding(
                                          padding: EdgeInsets.all(14),
                                          child: SizedBox(
                                            width: 18,
                                            height: 18,
                                            child: CircularProgressIndicator(
                                              strokeWidth: 2,
                                            ),
                                          ),
                                        )
                                      : null,
                                  validator: (v) =>
                                      v == null || v.trim().isEmpty
                                          ? 'Ingrese su numero de documento'
                                          : null,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildGlassCard(
                            icon: Icons.lock_outline_rounded,
                            title: 'Cuenta',
                            subtitle: 'Credenciales de acceso',
                            child: Column(
                              children: [
                                _buildField(
                                  controller: _emailController,
                                  label: 'Correo electronico',
                                  hint: 'tu@correo.com',
                                  icon: Icons.mail_outline_rounded,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Ingrese su email';
                                    }
                                    if (!v.contains('@') || !v.contains('.')) {
                                      return 'Email no valido';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _passwordController,
                                  label: 'Contrasena',
                                  hint: 'Minimo 8 caracteres',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _slateBlue,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Ingrese su contrasena';
                                    }
                                    if (v.length < 8) {
                                      return 'Minimo 8 caracteres';
                                    }
                                    if (!RegExp(r'[A-Z]').hasMatch(v)) {
                                      return 'Debe tener al menos una mayuscula';
                                    }
                                    if (!RegExp(r'[a-z]').hasMatch(v)) {
                                      return 'Debe tener al menos una minuscula';
                                    }
                                    if (!RegExp(r'[0-9]').hasMatch(v)) {
                                      return 'Debe tener al menos un numero';
                                    }
                                    return null;
                                  },
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _confirmPasswordController,
                                  label: 'Confirmar contrasena',
                                  hint: 'Repita su contrasena',
                                  icon: Icons.lock_outline_rounded,
                                  obscure: _obscureConfirmPassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _slateBlue,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscureConfirmPassword =
                                            !_obscureConfirmPassword),
                                  ),
                                  validator: (v) {
                                    if (v == null || v.isEmpty) {
                                      return 'Confirme su contrasena';
                                    }
                                    if (v != _passwordController.text) {
                                      return 'Las contrasenas no coinciden';
                                    }
                                    return null;
                                  },
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          _buildPasswordRequirements(),
                          const SizedBox(height: 16),
                          _buildTermsCheckbox(),
                          const SizedBox(height: 24),
                          _buildRegisterButton(authProvider),
                          const SizedBox(height: 20),
                          _buildLoginLink(),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAppBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.of(context).pop(),
            child: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: _deepBlue.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: _deepBlue,
                size: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
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
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: const Icon(
            Icons.person_add_alt_rounded,
            size: 40,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 20),
        const Text(
          'Crear Cuenta',
          style: TextStyle(
            fontSize: 28,
            fontWeight: FontWeight.w800,
            color: _textPrimary,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Unete a SmartStay y vive\nla experiencia premium',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 14,
            color: _textSecondary,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildGlassCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _deepBlue.withOpacity(0.06),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      _deepBlue.withOpacity(0.1),
                      _slateBlue.withOpacity(0.1),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: _deepBlue, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: _textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12,
                        color: _textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          child,
        ],
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffix,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: _softGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _deepBlue.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            obscureText: obscure,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: _textSecondary.withOpacity(0.6),
                fontSize: 14,
              ),
              prefixIcon: Icon(icon, color: _slateBlue, size: 20),
              suffixIcon: suffix,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _deepBlue, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Colors.red, width: 1.5),
              ),
            ),
            validator: validator,
          ),
        ),
      ],
    );
  }

  Widget _buildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Tipo de Documento',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _textSecondary,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: _softGrey,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _deepBlue.withOpacity(0.06),
              width: 1,
            ),
          ),
          child: DropdownButtonFormField<String>(
            value: _tipoDocumento,
            isExpanded: true,
            icon: const Icon(Icons.keyboard_arrow_down_rounded,
                color: _slateBlue),
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.article_outlined,
                  color: _slateBlue, size: 20),
              border: InputBorder.none,
              contentPadding: EdgeInsets.symmetric(vertical: 16),
            ),
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: _textPrimary,
            ),
            items: _tiposDocumento
                .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                .toList(),
            onChanged: (v) => setState(() => _tipoDocumento = v!),
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordRequirements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _slateBlue.withOpacity(0.06),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _slateBlue.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.info_outline_rounded,
                  color: _slateBlue, size: 18),
              const SizedBox(width: 8),
              const Text(
                'La contrasena debe contener:',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: _textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _reqItem('Minimo 8 caracteres'),
          _reqItem('Al menos una mayuscula'),
          _reqItem('Al menos una minuscula'),
          _reqItem('Al menos un numero'),
        ],
      ),
    );
  }

  Widget _reqItem(String text) {
    return Padding(
      padding: const EdgeInsets.only(top: 6),
      child: Row(
        children: [
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: _slateBlue.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check, size: 10, color: _slateBlue),
          ),
          const SizedBox(width: 10),
          Text(
            text,
            style: const TextStyle(fontSize: 12, color: _textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildTermsCheckbox() {
    return GestureDetector(
      onTap: () => setState(() => _acceptedTerms = !_acceptedTerms),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _acceptedTerms
                ? _deepBlue.withOpacity(0.3)
                : _deepBlue.withOpacity(0.06),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: _deepBlue.withOpacity(0.04),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: _acceptedTerms ? _deepBlue : Colors.transparent,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(
                  color: _acceptedTerms
                      ? _deepBlue
                      : _textSecondary.withOpacity(0.4),
                  width: 1.5,
                ),
              ),
              child: _acceptedTerms
                  ? const Icon(Icons.check, color: Colors.white, size: 14)
                  : null,
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'Acepto los terminos y condiciones',
                style: TextStyle(
                  fontSize: 14,
                  color: _textPrimary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRegisterButton(AuthProvider authProvider) {
    return Container(
      width: double.infinity,
      height: 56,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_deepBlue, _slateBlue],
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: _deepBlue.withOpacity(0.35),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: authProvider.isLoading ? null : _handleRegister,
          child: Center(
            child: authProvider.isLoading
                ? const SizedBox(
                    height: 22,
                    width: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Registrarse',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward_rounded,
                          color: Colors.white, size: 20),
                    ],
                  ),
          ),
        ),
      ),
    );
  }

  Widget _buildLoginLink() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text(
          'Ya tienes cuenta? ',
          style: TextStyle(color: _textSecondary, fontSize: 14),
        ),
        GestureDetector(
          onTap: () => Navigator.of(context).pop(),
          child: const Text(
            'Inicia sesion',
            style: TextStyle(
              color: _deepBlue,
              fontWeight: FontWeight.w700,
              fontSize: 14,
            ),
          ),
        ),
      ],
    );
  }
}