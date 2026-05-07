import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart'
    hide NotificationVisibility;
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/notificacion.dart';
import 'api/ntfy_service.dart';
import 'ntfy_foreground_handler.dart';

class NotificacionesProvider with ChangeNotifier {
  List<Notificacion> _notificaciones = [];
  bool _notificacionesActivas = true;
  bool _modoNoMolestar = false;
  String _horaInicioNoMolestar = '22:00';
  String _horaFinNoMolestar = '08:00';
  bool _ntfyRunning = false;

  final NtfyService _ntfyService = NtfyService();
  StreamSubscription<NtfyMessage>? _ntfySubscription;

  static final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  List<Notificacion> get notificaciones => _notificaciones;
  List<Notificacion> get notificacionesNoLeidas =>
      _notificaciones.where((n) => !n.leida).toList();
  int get cantidadNoLeidas => notificacionesNoLeidas.length;
  bool get notificacionesActivas => _notificacionesActivas;
  bool get modoNoMolestar => _modoNoMolestar;
  String get horaInicioNoMolestar => _horaInicioNoMolestar;
  String get horaFinNoMolestar => _horaFinNoMolestar;
  bool get ntfyConnected => _ntfyRunning;

  static Future<void> initLocalNotifications() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const settings = InitializationSettings(android: android, iOS: ios);
    await _localNotifications.initialize(settings);

    // Request notification permission on Android 13+
    if (Platform.isAndroid) {
      await Permission.notification.request();
    }
  }

  Future<void> startNtfy(String accessToken) async {
    debugPrint('[NotificacionesProvider] startNtfy called');

    // Save token for foreground isolate
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('ntfy_access_token', accessToken);

    // 1. Connect directly via NtfyService (main isolate — visible logs)
    _ntfySubscription?.cancel();
    _ntfySubscription = _ntfyService.messages.listen(_onNtfyMessage);
    await _ntfyService.connect(accessToken);
    debugPrint('[NotificacionesProvider] NtfyService.connect done, connected=${_ntfyService.isConnected}');

    // 2. Start foreground service for background listening
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'smartstay_ntfy_channel',
        channelName: 'SmartStay',
        channelDescription: 'Notificaciones en tiempo real',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.repeat(30000),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: true,
      ),
    );

    FlutterForegroundTask.addTaskDataCallback(_onTaskData);

    final isRunning = await FlutterForegroundTask.isRunningService;
    if (isRunning) {
      await FlutterForegroundTask.restartService();
    } else {
      await FlutterForegroundTask.startService(
        serviceId: 300,
        notificationTitle: 'SmartStay',
        notificationText: 'Conectado a notificaciones',
        callback: ntfyTaskCallback,
      );
    }

    _ntfyRunning = true;
    notifyListeners();
    debugPrint('[NotificacionesProvider] ntfy fully started');
  }

  Future<void> stopNtfy() async {
    debugPrint('[NotificacionesProvider] stopNtfy called');

    // Stop direct connection
    _ntfySubscription?.cancel();
    _ntfySubscription = null;
    await _ntfyService.disconnect();

    // Stop foreground service
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    await FlutterForegroundTask.stopService();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('ntfy_access_token');

    _ntfyRunning = false;
    notifyListeners();
  }

  void _onTaskData(Object data) {
    if (data is! String) return;
    try {
      final json = jsonDecode(data) as Map<String, dynamic>;
      final msg = NtfyMessage.fromJson(json);
      debugPrint('[NotificacionesProvider] Received from foreground task: ${msg.title}');
      _onNtfyMessage(msg);
    } catch (e) {
      debugPrint('[NotificacionesProvider] _onTaskData parse error: $e');
    }
  }

  void _onNtfyMessage(NtfyMessage msg) {
    debugPrint('[NotificacionesProvider] _onNtfyMessage: ${msg.title} - ${msg.message}');
    if (!_notificacionesActivas || _modoNoMolestar) return;

    // Deduplicate by message id
    if (msg.id.isNotEmpty && _notificaciones.any((n) => n.id == msg.id)) {
      debugPrint('[NotificacionesProvider] Duplicate message ${msg.id}, skipping');
      return;
    }

    final tipo = _inferirTipo(msg.tags);

    final notif = Notificacion(
      id: msg.id.isNotEmpty
          ? msg.id
          : DateTime.now().millisecondsSinceEpoch.toString(),
      idUsuario: msg.topic,
      titulo: msg.title,
      mensaje: msg.message,
      fecha: msg.time,
      tipo: tipo,
      leida: false,
    );

    _notificaciones.insert(0, notif);
    notifyListeners();

    _showLocalNotification(msg);
  }

  String _inferirTipo(List<String> tags) {
    final lower = tags.map((t) => t.toLowerCase()).toList();
    if (lower.any((t) => t.contains('acceso') || t.contains('access'))) {
      return 'acceso';
    }
    if (lower.any((t) => t.contains('reserva') || t.contains('booking'))) {
      return 'reserva';
    }
    if (lower.any((t) => t.contains('actividad') || t.contains('activity'))) {
      return 'actividad';
    }
    return 'sistema';
  }

  Future<void> _showLocalNotification(NtfyMessage msg) async {
    debugPrint('[NotificacionesProvider] Showing local notification: ${msg.title}');
    const androidDetails = AndroidNotificationDetails(
      'smartstay_notifications',
      'Notificaciones SmartStay',
      channelDescription: 'Notificaciones del hotel SmartStay',
      importance: Importance.max,
      priority: Priority.max,
      playSound: true,
      enableVibration: true,
      fullScreenIntent: true,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _localNotifications.show(
      msg.id.hashCode,
      msg.title,
      msg.message,
      details,
    );
  }

  Future<void> cargarNotificaciones(String idUsuario) async {
    // placeholder — real notifications come via ntfy stream
  }

  void agregarNotificacion(Notificacion notificacion) {
    _notificaciones.insert(0, notificacion);
    notifyListeners();
  }

  void marcarComoLeida(String idNotificacion) {
    final index = _notificaciones.indexWhere((n) => n.id == idNotificacion);
    if (index != -1) {
      _notificaciones[index] = _notificaciones[index].copyWith(leida: true);
      notifyListeners();
    }
  }

  void marcarTodasComoLeidas() {
    _notificaciones = _notificaciones.map((n) => n.copyWith(leida: true)).toList();
    notifyListeners();
  }

  void eliminarNotificacion(String idNotificacion) {
    _notificaciones.removeWhere((n) => n.id == idNotificacion);
    notifyListeners();
  }

  void toggleNotificaciones(bool valor) {
    _notificacionesActivas = valor;
    notifyListeners();
  }

  void toggleModoNoMolestar(bool valor) {
    _modoNoMolestar = valor;
    notifyListeners();
  }

  void configurarHorarioNoMolestar(String inicio, String fin) {
    _horaInicioNoMolestar = inicio;
    _horaFinNoMolestar = fin;
    notifyListeners();
  }

  void simularNotificacionAcceso({
    required String idUsuario,
    required String personal,
    required String motivo,
  }) {
    if (!_notificacionesActivas || _modoNoMolestar) return;

    final nuevaNotificacion = Notificacion(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      idUsuario: idUsuario,
      titulo: 'Acceso de Personal Autorizado',
      mensaje: '$personal accedió a su habitación.',
      fecha: DateTime.now(),
      tipo: 'acceso',
      datos: {
        'personal': personal,
        'motivo': motivo,
        'hora':
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}',
      },
    );

    agregarNotificacion(nuevaNotificacion);
  }

  @override
  void dispose() {
    _ntfySubscription?.cancel();
    _ntfyService.dispose();
    FlutterForegroundTask.removeTaskDataCallback(_onTaskData);
    super.dispose();
  }
}
