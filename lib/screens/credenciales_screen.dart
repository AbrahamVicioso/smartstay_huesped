import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/api/credencial_acceso.dart';
import '../services/api/credenciales_service.dart';
import '../services/biometric_service.dart';
import '../theme/app_theme.dart';

class CredencialesScreen extends StatefulWidget {
  const CredencialesScreen({super.key});

  @override
  State<CredencialesScreen> createState() => _CredencialesScreenState();
}

class _CredencialesScreenState extends State<CredencialesScreen> {
  final _service = CredencialesService();
  List<CredencialAcceso> _credenciales = [];
  bool _isLoading = true;
  String? _error;

  // tracks which credencialIds have PIN revealed
  final Set<int> _pinVisible = {};
  // tracks which credencialIds are toggling
  final Set<int> _toggling = {};

  @override
  void initState() {
    super.initState();
    _cargar();
  }

  Future<void> _cargar() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final list = await _service.getMisCredenciales();
      if (mounted) setState(() => _credenciales = list);
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _togglePin(CredencialAcceso cred) async {
    if (_pinVisible.contains(cred.credencialId)) {
      setState(() => _pinVisible.remove(cred.credencialId));
      return;
    }
    final authed = await BiometricService.authenticate(
      'Verifica tu identidad para ver el PIN',
    );
    if (!mounted || !authed) return;
    setState(() => _pinVisible.add(cred.credencialId));
  }

  Future<void> _toggleActiva(CredencialAcceso cred) async {
    final authed = await BiometricService.authenticate(
      cred.estaActiva
          ? 'Verifica tu identidad para desactivar la credencial'
          : 'Verifica tu identidad para activar la credencial',
    );
    if (!mounted || !authed) return;

    setState(() => _toggling.add(cred.credencialId));
    try {
      await _service.toggleCredencial(cred.credencialId);
      // optimistic update
      setState(() {
        final idx = _credenciales.indexWhere((c) => c.credencialId == cred.credencialId);
        if (idx != -1) {
          _credenciales[idx] = cred.copyWith(estaActiva: !cred.estaActiva);
        }
      });
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().replaceFirst('Exception: ', '');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(msg), backgroundColor: Colors.red),
      );
    } finally {
      if (mounted) setState(() => _toggling.remove(cred.credencialId));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Credenciales de Acceso'),
        backgroundColor: AppColors.background,
        foregroundColor: AppColors.secondary,
        elevation: 0,
        actions: [
          IconButton(
            icon: _isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.refresh_rounded),
            onPressed: _isLoading ? null : _cargar,
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 16),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _cargar,
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    if (_credenciales.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppTheme.primaryColor.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.key_off_outlined,
                  size: 48,
                  color: AppTheme.primaryColor,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Sin credenciales',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(height: 8),
              Text(
                'No tienes credenciales de acceso asignadas',
                style: TextStyle(color: AppTheme.textSecondary, fontSize: 13),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _cargar,
      color: AppTheme.primaryColor,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: _credenciales.length,
        itemBuilder: (context, index) {
          return _CredencialCard(
            credencial: _credenciales[index],
            pinVisible: _pinVisible.contains(_credenciales[index].credencialId),
            isToggling: _toggling.contains(_credenciales[index].credencialId),
            onTogglePin: () => _togglePin(_credenciales[index]),
            onToggleActiva: () => _toggleActiva(_credenciales[index]),
          );
        },
      ),
    );
  }
}

class _CredencialCard extends StatelessWidget {
  final CredencialAcceso credencial;
  final bool pinVisible;
  final bool isToggling;
  final VoidCallback onTogglePin;
  final VoidCallback onToggleActiva;

  const _CredencialCard({
    required this.credencial,
    required this.pinVisible,
    required this.isToggling,
    required this.onTogglePin,
    required this.onToggleActiva,
  });

  @override
  Widget build(BuildContext context) {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    final now = DateTime.now();
    final expired = credencial.fechaExpiracion.isBefore(now);
    final statusColor = !credencial.estaActiva
        ? Colors.grey
        : expired
            ? Colors.orange
            : Colors.green;

    final tipoLabel = _tipoLabel(credencial.tipoCredencial);
    final tipoIcon = _tipoIcon(credencial.tipoCredencial);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.08),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: Row(
              children: [
                Icon(tipoIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    tipoLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    !credencial.estaActiva
                        ? 'Inactiva'
                        : expired
                            ? 'Expirada'
                            : 'Activa',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // PIN row
                Row(
                  children: [
                    Icon(Icons.pin, size: 18, color: AppTheme.textSecondary),
                    const SizedBox(width: 8),
                    Text(
                      'PIN: ',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                    Expanded(
                      child: Text(
                        pinVisible ? credencial.codigoPin : '••••••',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                          letterSpacing: 2,
                        ),
                      ),
                    ),
                    IconButton(
                      onPressed: onTogglePin,
                      icon: Icon(
                        pinVisible ? Icons.visibility_off : Icons.visibility,
                        color: AppTheme.primaryColor,
                        size: 22,
                      ),
                      tooltip: pinVisible ? 'Ocultar PIN' : 'Ver PIN',
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),

                const SizedBox(height: 12),
                Divider(color: Colors.grey.shade200),
                const SizedBox(height: 12),

                // Dates
                Row(
                  children: [
                    Expanded(
                      child: _DateItem(
                        label: 'Activación',
                        value: fmt.format(credencial.fechaActivacion),
                        icon: Icons.play_circle_outline,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _DateItem(
                        label: 'Expiración',
                        value: fmt.format(credencial.fechaExpiracion),
                        icon: Icons.timer_off_outlined,
                        color: expired ? Colors.orange : Colors.grey,
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                // Usos
                Row(
                  children: [
                    Icon(Icons.touch_app_outlined,
                        size: 16, color: AppTheme.textSecondary),
                    const SizedBox(width: 6),
                    Text(
                      'Usos registrados: ${credencial.numeroUsos}',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),

                if (credencial.reservaId != null ||
                    credencial.reservaActividadId != null) ...[
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Icon(Icons.link, size: 16, color: AppTheme.textSecondary),
                      const SizedBox(width: 6),
                      Text(
                        credencial.reservaId != null
                            ? 'Reserva #${credencial.reservaId}'
                            : 'Actividad #${credencial.reservaActividadId}',
                        style: TextStyle(
                          color: AppTheme.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 16),

                // Toggle button
                SizedBox(
                  width: double.infinity,
                  child: isToggling
                      ? const Center(child: CircularProgressIndicator())
                      : OutlinedButton.icon(
                          onPressed: expired ? null : onToggleActiva,
                          icon: Icon(
                            credencial.estaActiva
                                ? Icons.lock_outline
                                : Icons.lock_open_outlined,
                          ),
                          label: Text(
                            credencial.estaActiva
                                ? 'Desactivar credencial'
                                : 'Activar credencial',
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: credencial.estaActiva
                                ? Colors.red
                                : Colors.green,
                            side: BorderSide(
                              color: credencial.estaActiva
                                  ? Colors.red
                                  : Colors.green,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
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

  String _tipoLabel(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'habitacion':
      case 'habitación':
      case 'room':
        return 'Habitación';
      case 'actividad':
      case 'activity':
        return 'Actividad';
      case 'pin':
        return 'PIN';
      default:
        return tipo.isNotEmpty ? tipo : 'Credencial';
    }
  }

  IconData _tipoIcon(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'habitacion':
      case 'habitación':
      case 'room':
        return Icons.hotel;
      case 'actividad':
      case 'activity':
        return Icons.local_activity_outlined;
      default:
        return Icons.key_outlined;
    }
  }
}

class _DateItem extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _DateItem({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ],
      ),
    );
  }
}
