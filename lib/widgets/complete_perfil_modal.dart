import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';

const Color _deepBlue = Color(0xFF003366);
const Color _slateBlue = Color(0xFF336699);
const Color _gold = Color(0xFFD4AF37);
const Color _softGrey = Color(0xFFF8FAFC);
const Color _textPrimary = Color(0xFF0F172A);
const Color _textSecondary = Color(0xFF64748B);

Future<void> showCompletePerfilModal(BuildContext context) {
  return showDialog(
    context: context,
    barrierDismissible: false,
    builder: (_) => const _CompletePerfilDialog(),
  );
}

class _CompletePerfilDialog extends StatefulWidget {
  const _CompletePerfilDialog();

  @override
  State<_CompletePerfilDialog> createState() => _CompletePerfilDialogState();
}

class _CompletePerfilDialogState extends State<_CompletePerfilDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nombreCtrl = TextEditingController();
  final _documentoCtrl = TextEditingController();
  final _nacionalidadCtrl = TextEditingController(text: 'Dominicana');
  final _contactoCtrl = TextEditingController();
  final _telefonoCtrl = TextEditingController();

  int _tipoDocumentoId = 2; // Cédula por defecto
  DateTime? _fechaNacimiento;
  bool _loading = false;
  String? _error;

  static const _tiposDocumento = [
    {'id': 1, 'nombre': 'Pasaporte'},
    {'id': 2, 'nombre': 'Cédula'},
    {'id': 3, 'nombre': 'Licencia de Conducir'},
    {'id': 4, 'nombre': 'Otro'},
  ];

  @override
  void dispose() {
    _nombreCtrl.dispose();
    _documentoCtrl.dispose();
    _nacionalidadCtrl.dispose();
    _contactoCtrl.dispose();
    _telefonoCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFechaNacimiento() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1990, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: const ColorScheme.light(
            primary: _deepBlue,
            onPrimary: Colors.white,
            secondary: _gold,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _fechaNacimiento = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_fechaNacimiento == null) {
      setState(() => _error = 'Por favor selecciona tu fecha de nacimiento.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final auth = Provider.of<AuthProvider>(context, listen: false);
    try {
      final ok = await auth.crearPerfilHuesped({
        'nombreCompleto': _nombreCtrl.text.trim(),
        'tipoDocumentoId': _tipoDocumentoId,
        'numeroDocumento': _documentoCtrl.text.trim(),
        'nacionalidad': _nacionalidadCtrl.text.trim(),
        'fechaNacimiento': _fechaNacimiento!.toUtc().toIso8601String(),
        'contactoEmergencia': _contactoCtrl.text.trim().isEmpty ? null : _contactoCtrl.text.trim(),
        'telefonoEmergencia': _telefonoCtrl.text.trim().isEmpty ? null : _telefonoCtrl.text.trim(),
      });

      if (!mounted) return;

      if (ok) {
        Navigator.of(context).pop();
      } else {
        setState(() {
          _loading = false;
          _error = 'No se pudo guardar el perfil. Intenta de nuevo.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      // Extract readable message from Exception('...')
      final raw = e.toString();
      final msg = raw.startsWith('Exception: ') ? raw.substring(11) : raw;
      setState(() {
        _loading = false;
        _error = msg;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      clipBehavior: Clip.antiAlias,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_deepBlue, _slateBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, color: Colors.white, size: 28),
                ),
                const SizedBox(height: 14),
                const Text(
                  'Completa tu perfil',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Necesitamos algunos datos para brindarte la mejor experiencia.',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),

          // Form
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _label('Nombre completo *'),
                    _field(
                      controller: _nombreCtrl,
                      hint: 'Ej. Juan Pérez',
                      icon: Icons.badge_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Tipo de documento *'),
                    _dropdownField(),
                    const SizedBox(height: 16),

                    _label('Número de documento *'),
                    _field(
                      controller: _documentoCtrl,
                      hint: 'Ej. 001-1234567-8',
                      icon: Icons.credit_card_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Nacionalidad *'),
                    _field(
                      controller: _nacionalidadCtrl,
                      hint: 'Ej. Dominicana',
                      icon: Icons.flag_outlined,
                      validator: (v) => v == null || v.trim().isEmpty ? 'Campo requerido' : null,
                    ),
                    const SizedBox(height: 16),

                    _label('Fecha de nacimiento *'),
                    _datePickerTile(),
                    const SizedBox(height: 16),

                    _label('Contacto de emergencia'),
                    _field(
                      controller: _contactoCtrl,
                      hint: 'Nombre del contacto',
                      icon: Icons.contact_phone_outlined,
                    ),
                    const SizedBox(height: 16),

                    _label('Teléfono de emergencia'),
                    _field(
                      controller: _telefonoCtrl,
                      hint: '+1 809 000 0000',
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),

                    if (_error != null) ...[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade200),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.error_outline, color: Colors.red.shade600, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _error!,
                                style: TextStyle(color: Colors.red.shade700, fontSize: 13),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 24),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: _loading ? null : _submit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _deepBlue,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                        child: _loading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  valueColor: AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text(
                                'Guardar perfil',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Text(
          text,
          style: const TextStyle(
            color: _textPrimary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      );

  Widget _field({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      style: const TextStyle(fontSize: 15, color: _textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: _textSecondary, fontSize: 14),
        prefixIcon: Icon(icon, color: _slateBlue, size: 20),
        filled: true,
        fillColor: _softGrey,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _slateBlue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red.shade400, width: 1.5),
        ),
      ),
    );
  }

  Widget _dropdownField() {
    return Container(
      decoration: BoxDecoration(
        color: _softGrey,
        borderRadius: BorderRadius.circular(12),
        border: const Border.fromBorderSide(BorderSide(color: Color(0xFFE2E8F0))),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<int>(
          value: _tipoDocumentoId,
          isExpanded: true,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          borderRadius: BorderRadius.circular(12),
          icon: const Icon(Icons.keyboard_arrow_down, color: _slateBlue),
          style: const TextStyle(fontSize: 15, color: _textPrimary),
          items: _tiposDocumento
              .map((t) => DropdownMenuItem<int>(
                    value: t['id'] as int,
                    child: Row(
                      children: [
                        const Icon(Icons.article_outlined, color: _slateBlue, size: 20),
                        const SizedBox(width: 12),
                        Text(t['nombre'] as String),
                      ],
                    ),
                  ))
              .toList(),
          onChanged: (v) {
            if (v != null) setState(() => _tipoDocumentoId = v);
          },
        ),
      ),
    );
  }

  Widget _datePickerTile() {
    return GestureDetector(
      onTap: _pickFechaNacimiento,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _softGrey,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: _fechaNacimiento == null && _error != null
                ? Colors.red.shade400
                : const Color(0xFFE2E8F0),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.calendar_today_outlined, color: _slateBlue, size: 20),
            const SizedBox(width: 12),
            Text(
              _fechaNacimiento == null
                  ? 'Seleccionar fecha'
                  : '${_fechaNacimiento!.day.toString().padLeft(2, '0')}/${_fechaNacimiento!.month.toString().padLeft(2, '0')}/${_fechaNacimiento!.year}',
              style: TextStyle(
                fontSize: 15,
                color: _fechaNacimiento == null ? _textSecondary : _textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
