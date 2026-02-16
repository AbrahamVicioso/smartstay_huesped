import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../theme/app_theme.dart';
import 'package:intl/intl.dart';

class EditarPerfilScreen extends StatefulWidget {
  const EditarPerfilScreen({super.key});

  @override
  State<EditarPerfilScreen> createState() => _EditarPerfilScreenState();
}

class _EditarPerfilScreenState extends State<EditarPerfilScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  late TextEditingController _nombreCompletoController;
  late TextEditingController _tipoDocumentoController;
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _nacionalidadController;
  late TextEditingController _contactoEmergenciaController;
  late TextEditingController _telefonoEmergenciaController;
  late TextEditingController _preferenciasAlimentariasController;
  late TextEditingController _notasEspecialesController;

  DateTime? _fechaNacimiento;
  String _tipoDocumentoSeleccionado = 'Cedula';

  final List<String> _tiposDocumento = [
    'Cedula',
    'Cédula',
    'Pasaporte',
    'Licencia de Conducir',
    'Otro',
  ];

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final huesped = authProvider.huesped;

    _nombreCompletoController = TextEditingController(
      text: huesped?.nombreCompleto ?? '',
    );
    _tipoDocumentoController = TextEditingController(
      text: huesped?.tipoDocumento ?? 'Cedula',
    );
    _numeroDocumentoController = TextEditingController(
      text: huesped?.numeroDocumento ?? '',
    );
    _nacionalidadController = TextEditingController(
      text: huesped?.nacionalidad ?? 'Dominicana',
    );
    _contactoEmergenciaController = TextEditingController(
      text: huesped?.contactoEmergencia ?? '',
    );
    _telefonoEmergenciaController = TextEditingController(
      text: huesped?.telefonoEmergencia ?? '',
    );
    _preferenciasAlimentariasController = TextEditingController(
      text: huesped?.preferenciasAlimentarias ?? '',
    );
    _notasEspecialesController = TextEditingController(
      text: huesped?.notasEspeciales ?? '',
    );

    _fechaNacimiento = huesped?.fechaNacimiento;
    _tipoDocumentoSeleccionado = huesped?.tipoDocumento ?? 'Cedula';
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
    _tipoDocumentoController.dispose();
    _numeroDocumentoController.dispose();
    _nacionalidadController.dispose();
    _contactoEmergenciaController.dispose();
    _telefonoEmergenciaController.dispose();
    _preferenciasAlimentariasController.dispose();
    _notasEspecialesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _fechaNacimiento ?? DateTime(2000, 1, 1),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _fechaNacimiento = picked;
      });
    }
  }

  Future<void> _guardarCambios() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final huespedActual = authProvider.huesped;

    if (huespedActual == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No se encontró el perfil de huésped'),
          backgroundColor: Colors.red,
        ),
      );
      setState(() => _isLoading = false);
      return;
    }

    final updatedHuesped = huespedActual.copyWith(
      nombreCompleto: _nombreCompletoController.text.trim(),
      tipoDocumento: _tipoDocumentoSeleccionado,
      numeroDocumento: _numeroDocumentoController.text.trim(),
      nacionalidad: _nacionalidadController.text.trim(),
      fechaNacimiento: _fechaNacimiento,
      contactoEmergencia: _contactoEmergenciaController.text.trim().isEmpty
          ? null
          : _contactoEmergenciaController.text.trim(),
      telefonoEmergencia: _telefonoEmergenciaController.text.trim().isEmpty
          ? null
          : _telefonoEmergenciaController.text.trim(),
      preferenciasAlimentarias:
          _preferenciasAlimentariasController.text.trim().isEmpty
          ? null
          : _preferenciasAlimentariasController.text.trim(),
      notasEspeciales: _notasEspecialesController.text.trim().isEmpty
          ? null
          : _notasEspecialesController.text.trim(),
    );

    final success = await authProvider.updateHuesped(updatedHuesped);

    if (!mounted) return;

    setState(() => _isLoading = false);

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Perfil actualizado exitosamente'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.of(context).pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Error al actualizar el perfil'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Editar Información Personal')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Card(
                color: AppTheme.primaryColor.withOpacity(0.1),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: AppTheme.primaryColor),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Complete o actualice su información personal como huésped.',
                          style: Theme.of(context).textTheme.bodyMedium
                              ?.copyWith(color: AppTheme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Nombre Completo
              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  prefixIcon: Icon(Icons.person),
                  hintText: 'Ej: Juan Pérez',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El nombre es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Tipo de Documento
              DropdownButtonFormField<String>(
                value: _tiposDocumento.contains(_tipoDocumentoSeleccionado)
                    ? _tipoDocumentoSeleccionado
                    : 'Cedula',
                decoration: const InputDecoration(
                  labelText: 'Tipo de Documento *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: _tiposDocumento.map((tipo) {
                  return DropdownMenuItem(value: tipo, child: Text(tipo));
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _tipoDocumentoSeleccionado = value ?? 'Cedula';
                  });
                },
              ),
              const SizedBox(height: 16),

              // Número de Documento
              TextFormField(
                controller: _numeroDocumentoController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento *',
                  prefixIcon: Icon(Icons.credit_card),
                  hintText: 'Ej: 001-1234567-8',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'El número de documento es requerido';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Nacionalidad
              TextFormField(
                controller: _nacionalidadController,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidad *',
                  prefixIcon: Icon(Icons.flag),
                  hintText: 'Ej: Dominicana',
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'La nacionalidad es requerida';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Fecha de Nacimiento
              InkWell(
                onTap: _selectDate,
                child: InputDecorator(
                  decoration: const InputDecoration(
                    labelText: 'Fecha de Nacimiento',
                    prefixIcon: Icon(Icons.calendar_today),
                  ),
                  child: Text(
                    _fechaNacimiento != null
                        ? DateFormat('dd/MM/yyyy').format(_fechaNacimiento!)
                        : 'Seleccionar fecha',
                    style: TextStyle(
                      color: _fechaNacimiento != null
                          ? Theme.of(context).textTheme.bodyLarge?.color
                          : AppTheme.textSecondary,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Sección de Emergencia
              Text(
                'Contacto de Emergencia',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _contactoEmergenciaController,
                decoration: const InputDecoration(
                  labelText: 'Nombre del Contacto',
                  prefixIcon: Icon(Icons.contact_phone),
                  hintText: 'Ej: María Pérez',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _telefonoEmergenciaController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Teléfono de Emergencia',
                  prefixIcon: Icon(Icons.phone),
                  hintText: 'Ej: 8095551234',
                ),
              ),
              const SizedBox(height: 24),

              // Sección de Preferencias
              Text(
                'Preferencias',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppTheme.primaryColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _preferenciasAlimentariasController,
                decoration: const InputDecoration(
                  labelText: 'Preferencias Alimentarias',
                  prefixIcon: Icon(Icons.restaurant_menu),
                  hintText: 'Ej: Vegetariano, Sin gluten',
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _notasEspecialesController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Notas Especiales',
                  prefixIcon: Icon(Icons.note),
                  hintText: 'Cualquier información adicional...',
                  alignLabelWithHint: true,
                ),
              ),
              const SizedBox(height: 32),

              // Botón Guardar
              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarCambios,
                  child: _isLoading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        )
                      : const Text(
                          'Guardar Cambios',
                          style: TextStyle(fontSize: 16),
                        ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
