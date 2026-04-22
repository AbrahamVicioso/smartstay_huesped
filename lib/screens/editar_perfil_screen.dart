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
  late TextEditingController _numeroDocumentoController;
  late TextEditingController _nacionalidadController;
  late TextEditingController _contactoEmergenciaController;
  late TextEditingController _telefonoEmergenciaController;
  late TextEditingController _preferenciasAlimentariasController;
  late TextEditingController _notasEspecialesController;

  DateTime? _fechaNacimiento;

  // ✅ NUEVO: usar ID en vez de String
  int _tipoDocumentoIdSeleccionado = 1;

  @override
  void initState() {
    super.initState();
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final huesped = authProvider.huesped;

    _nombreCompletoController = TextEditingController(
      text: huesped?.nombreCompleto ?? '',
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

    // ✅ NUEVO
    _tipoDocumentoIdSeleccionado = huesped?.tipoDocumentoId ?? 1;
  }

  @override
  void dispose() {
    _nombreCompletoController.dispose();
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

    // ✅ COPYWITH CORREGIDO
    final updatedHuesped = huespedActual.copyWith(
      nombreCompleto: _nombreCompletoController.text.trim(),
      tipoDocumentoId: _tipoDocumentoIdSeleccionado,
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

              TextFormField(
                controller: _nombreCompletoController,
                decoration: const InputDecoration(
                  labelText: 'Nombre Completo *',
                  prefixIcon: Icon(Icons.person),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'El nombre es requerido'
                        : null,
              ),
              const SizedBox(height: 16),

              // ✅ DROPDOWN CON ID
              DropdownButtonFormField<int>(
                value: _tipoDocumentoIdSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Tipo de Documento *',
                  prefixIcon: Icon(Icons.badge),
                ),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('Cédula')),
                  DropdownMenuItem(value: 2, child: Text('Pasaporte')),
                  DropdownMenuItem(value: 3, child: Text('Licencia de Conducir')),
                  DropdownMenuItem(value: 4, child: Text('Otro')),
                ],
                onChanged: (value) {
                  setState(() => _tipoDocumentoIdSeleccionado = value ?? 1);
                },
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _numeroDocumentoController,
                decoration: const InputDecoration(
                  labelText: 'Número de Documento *',
                  prefixIcon: Icon(Icons.credit_card),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'El número de documento es requerido'
                        : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _nacionalidadController,
                decoration: const InputDecoration(
                  labelText: 'Nacionalidad *',
                  prefixIcon: Icon(Icons.flag),
                ),
                validator: (value) =>
                    value == null || value.trim().isEmpty
                        ? 'La nacionalidad es requerida'
                        : null,
              ),
              const SizedBox(height: 16),

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
                  ),
                ),
              ),

              const SizedBox(height: 32),

              SizedBox(
                height: 50,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _guardarCambios,
                  child: _isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text('Guardar Cambios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}