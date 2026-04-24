import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/reserva.dart';
import '../models/api/habitacion.dart';
import '../services/api/nfc_hce_service.dart';
import '../theme/app_theme.dart';

class AperturaNFCModal extends StatefulWidget {
  final dynamic habitacionData;
  final Map<String, dynamic>? credentialData;

  const AperturaNFCModal({
    super.key,
    required this.habitacionData,
    this.credentialData,
  });

  @override
  State<AperturaNFCModal> createState() => _AperturaNFCModalState();
}

class _AperturaNFCModalState extends State<AperturaNFCModal>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _keyController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _keyRotationAnimation;
  late Animation<double> _keyScaleAnimation;

  bool _isScanning = true;
  bool _isSuccess = false;
  bool _isError = false;
  bool _hceStarted = false;
  bool _showDebug = false;

  final List<ApduEvent> _apduLog = [];
  StreamSubscription<ApduEvent>? _apduSub;
  Timer? _statusTimer;
  HceStatus? _hceStatus;

  String get _numeroHabitacion {
    final data = widget.habitacionData;
    if (data is Habitacion) return data.numeroHabitacion;
    if (data is Reserva) return data.numeroHabitacion;
    return '-';
  }

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.3).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _keyController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );

    _keyRotationAnimation = Tween<double>(begin: 0, end: math.pi / 4).animate(
      CurvedAnimation(parent: _keyController, curve: Curves.easeInOut),
    );

    _keyScaleAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _keyController, curve: Curves.easeInOut),
    );

    _startHce();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _keyController.dispose();
    _apduSub?.cancel();
    _statusTimer?.cancel();
    NfcHceService.stopEmulation();
    super.dispose();
  }

  Future<void> _startHce() async {
    final credential = widget.credentialData ??
        {'pin': 'demo', 'timestamp': DateTime.now().toIso8601String()};

    final ok = await NfcHceService.startEmulation(credential);
    if (!mounted) return;

    setState(() => _hceStarted = ok);

    if (!ok) {
      setState(() {
        _isScanning = false;
        _isError = true;
      });
      return;
    }

    // Listen for real APDU events from the lock
    _apduSub = NfcHceService.apduEvents.listen((event) {
      if (!mounted) return;
      setState(() => _apduLog.insert(0, event));

      // If we got a valid response (ends with 9000) — success
      if (event.response.toUpperCase().endsWith('9000')) {
        _onSuccess();
      }
    });

    // Poll HCE status every 2 s to confirm data is in SharedPreferences
    _statusTimer = Timer.periodic(const Duration(seconds: 2), (_) async {
      final status = await NfcHceService.getStatus();
      if (mounted) setState(() => _hceStatus = status);
    });

    // Initial status read
    NfcHceService.getStatus().then((s) {
      if (mounted) setState(() => _hceStatus = s);
    });
  }

  Future<void> _onSuccess() async {
    if (_isSuccess) return;
    _pulseController.stop();
    _apduSub?.cancel();
    _statusTimer?.cancel();

    setState(() {
      _isScanning = false;
      _isSuccess = true;
    });

    await _keyController.forward();
    await Future.delayed(const Duration(milliseconds: 1500));

    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Text('Habitación $_numeroHabitacion abierta'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(28),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildMainIcon(),
            const SizedBox(height: 20),
            _buildTitle(),
            const SizedBox(height: 8),
            _buildSubtitle(),
            const SizedBox(height: 16),
            _buildHceStatusBadge(),
            const SizedBox(height: 12),
            _buildDebugToggle(),
            if (_showDebug) ...[
              const SizedBox(height: 8),
              _buildDebugPanel(),
            ],
            if (_isScanning) ...[
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  NfcHceService.stopEmulation();
                  Navigator.of(context).pop();
                },
                child: const Text('Cancelar'),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMainIcon() {
    if (_isSuccess) {
      return AnimatedBuilder(
        animation: _keyController,
        builder: (context, _) => Transform.scale(
          scale: _keyScaleAnimation.value,
          child: Transform.rotate(
            angle: _keyRotationAnimation.value,
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.green.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.vpn_key, size: 64, color: Colors.green),
            ),
          ),
        ),
      );
    }

    if (_isError) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.red.withOpacity(0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(Icons.nfc, size: 64, color: Colors.red),
      );
    }

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, _) => Transform.scale(
        scale: _pulseAnimation.value,
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.nfc, size: 64, color: Colors.orange),
        ),
      ),
    );
  }

  Widget _buildTitle() {
    final text = _isSuccess
        ? '¡Puerta Abierta!'
        : _isError
            ? 'Error NFC'
            : 'Llave Digital Activa';
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .headlineSmall
          ?.copyWith(fontWeight: FontWeight.bold),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildSubtitle() {
    final text = _isSuccess
        ? 'Habitación $_numeroHabitacion abierta'
        : _isError
            ? 'No se pudo activar NFC HCE'
            : 'Acerca el teléfono al lector de la puerta';
    return Text(
      text,
      style: Theme.of(context)
          .textTheme
          .bodyMedium
          ?.copyWith(color: AppTheme.textSecondary),
      textAlign: TextAlign.center,
    );
  }

  Widget _buildHceStatusBadge() {
    if (_hceStatus == null) {
      return const SizedBox(
        height: 16,
        width: 16,
        child: CircularProgressIndicator(strokeWidth: 2),
      );
    }

    final active = _hceStatus!.isActive && _hceStatus!.hasData;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: active
            ? Colors.green.withOpacity(0.1)
            : Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: active
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            active ? Icons.radio_button_checked : Icons.radio_button_off,
            size: 12,
            color: active ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 6),
          Text(
            active
                ? 'HCE activo · ${_hceStatus!.apduCount} APDU${_hceStatus!.apduCount != 1 ? 's' : ''} recibidos'
                : 'HCE inactivo',
            style: TextStyle(
              fontSize: 12,
              color: active ? Colors.green.shade700 : Colors.red.shade700,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugToggle() {
    return GestureDetector(
      onTap: () => setState(() => _showDebug = !_showDebug),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _showDebug ? Icons.expand_less : Icons.expand_more,
            size: 16,
            color: AppTheme.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            _showDebug ? 'Ocultar debug' : 'Ver debug',
            style: TextStyle(fontSize: 12, color: AppTheme.textSecondary),
          ),
        ],
      ),
    );
  }

  Widget _buildDebugPanel() {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxHeight: 200),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_hceStatus != null) ...[
            _DebugLine(
                label: 'Active',
                value: _hceStatus!.isActive.toString(),
                ok: _hceStatus!.isActive),
            _DebugLine(
                label: 'Data',
                value: _hceStatus!.hasData
                    ? _hceStatus!.dataPreview
                    : 'null',
                ok: _hceStatus!.hasData),
            if (_hceStatus!.lastApduReceived.isNotEmpty)
              _DebugLine(
                  label: 'Last APDU',
                  value: _hceStatus!.lastApduReceived,
                  ok: true),
            const Divider(color: Colors.white24, height: 8),
          ],
          if (_apduLog.isEmpty)
            const Text(
              'Esperando APDU del lector...',
              style: TextStyle(color: Colors.white54, fontSize: 11),
            )
          else
            Flexible(
              child: ListView.builder(
                shrinkWrap: true,
                reverse: false,
                itemCount: _apduLog.length,
                itemBuilder: (_, i) {
                  final e = _apduLog[i];
                  final ok = e.response.toUpperCase().endsWith('9000');
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _DebugLine(label: 'APDU', value: e.apdu, ok: true),
                        _DebugLine(
                            label: 'RESP',
                            value: ok ? '...9000 ✓' : e.response,
                            ok: ok),
                      ],
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }
}

class _DebugLine extends StatelessWidget {
  final String label;
  final String value;
  final bool ok;

  const _DebugLine(
      {required this.label, required this.value, required this.ok});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              color: Colors.white54,
              fontSize: 10,
              fontFamily: 'monospace',
            ),
          ),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: ok ? Colors.greenAccent : Colors.redAccent,
                fontSize: 10,
                fontFamily: 'monospace',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OndasNFC extends StatelessWidget {
  final AnimationController controller;
  final double delay;

  const _OndasNFC({required this.controller, required this.delay});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: controller,
      builder: (context, _) {
        final progress = ((controller.value + delay) % 1.0);
        return Opacity(
          opacity: 1.0 - progress,
          child: Container(
            width: 60 + (progress * 80),
            height: 60 + (progress * 80),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.orange, width: 2),
            ),
          ),
        );
      },
    );
  }
}
