import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/api_config.dart';

@pragma('vm:entry-point')
void ntfyTaskCallback() {
  FlutterForegroundTask.setTaskHandler(NtfyTaskHandler());
}

class NtfyTaskHandler extends TaskHandler {
  HttpClient? _httpClient;
  HttpClientResponse? _response;
  StreamSubscription? _subscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ntfy_access_token');
    if (token != null) await _connect(token);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_subscription == null) _tryReconnect();
  }

  void _tryReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ntfy_access_token');
    if (token != null) await _connect(token);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _disconnect();
  }

  @override
  void onReceiveData(Object data) {
    if (data is String) _connect(data);
  }

  Future<void> _connect(String accessToken) async {
    await _disconnect();

    try {
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(hours: 24)
        ..badCertificateCallback = (_, __, ___) => true;

      // Fetch push config
      final configUri = Uri.parse(ApiConfig.pushConfigUrl);
      final configRequest = await _httpClient!.getUrl(configUri);
      configRequest.headers.set('Authorization', 'Bearer $accessToken');
      final configResponse = await configRequest.close();

      if (configResponse.statusCode != 200) {
        await configResponse.drain();
        return;
      }

      final configBody =
          await configResponse.transform(utf8.decoder).join();
      final configJson = jsonDecode(configBody) as Map<String, dynamic>;
      final topic = configJson['topic'] as String;
      final ntfyBaseUrl = configJson['ntfyBaseUrl'] as String;
      final ntfyToken = configJson['ntfyToken'] as String?;

      // Connect JSON stream to ntfy
      final effectiveBase = ApiConfig.ntfyBaseUrlOverride ?? ntfyBaseUrl;
      final jsonUri = Uri.parse('$effectiveBase/$topic/json');

      final jsonRequest = await _httpClient!.getUrl(jsonUri);
      jsonRequest.headers.set('Cache-Control', 'no-cache');
      jsonRequest.persistentConnection = true;
      if (ntfyToken != null && ntfyToken.isNotEmpty) {
        jsonRequest.headers.set('Authorization', 'Bearer $ntfyToken');
      }

      _response = await jsonRequest.close();

      _subscription = _response!
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isEmpty) return;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final event = json['event'] as String? ?? '';
            if (event == 'message') {
              FlutterForegroundTask.sendDataToMain(line);
            }
          } catch (_) {}
        },
        onDone: () => _subscription = null,
        cancelOnError: false,
      );
    } catch (_) {
      // onRepeatEvent will retry in 30s
    }
  }

  Future<void> _disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _response = null;
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
