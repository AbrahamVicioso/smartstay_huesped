import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

@pragma('vm:entry-point')
void ntfyTaskCallback() {
  FlutterForegroundTask.setTaskHandler(NtfyTaskHandler());
}

class NtfyTaskHandler extends TaskHandler {
  HttpClient? _httpClient;
  StreamSubscription? _sseSubscription;

  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ntfy_access_token');
    if (token != null) await _connectSse(token);
  }

  @override
  void onRepeatEvent(DateTime timestamp) {
    if (_sseSubscription == null) _tryReconnect();
  }

  void _tryReconnect() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('ntfy_access_token');
    if (token != null) await _connectSse(token);
  }

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    await _disconnect();
  }

  @override
  void onReceiveData(Object data) {
    // Receive updated token from main isolate (e.g. after token refresh)
    if (data is String) _connectSse(data);
  }

  Future<void> _connectSse(String accessToken) async {
    await _disconnect();

    try {
      final configResponse = await http.get(
        Uri.parse('https://smartstay.es/api/notifications/push-config'),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (configResponse.statusCode != 200) return;

      final configJson =
          jsonDecode(configResponse.body) as Map<String, dynamic>;
      final topic = configJson['topic'] as String;
      final ntfyBaseUrl = configJson['ntfyBaseUrl'] as String;
      final ntfyToken = configJson['ntfyToken'] as String?;

      final url = Uri.parse('$ntfyBaseUrl/$topic/sse');

      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 15);

      final request = await _httpClient!.getUrl(url);
      request.headers.set('Accept', 'text/event-stream');
      request.headers.set('Cache-Control', 'no-cache');
      if (ntfyToken != null && ntfyToken.isNotEmpty) {
        request.headers.set('Authorization', 'Bearer $ntfyToken');
      }

      final response = await request.close();

      String dataBuffer = '';
      _sseSubscription = response
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.startsWith('data:')) {
            dataBuffer += line.substring(5).trim();
          } else if (line.isEmpty && dataBuffer.isNotEmpty) {
            try {
              final json = jsonDecode(dataBuffer) as Map<String, dynamic>;
              if (json['event'] == 'message') {
                FlutterForegroundTask.sendDataToMain(dataBuffer);
              }
            } catch (_) {}
            dataBuffer = '';
          }
        },
        onDone: () => _sseSubscription = null,
        cancelOnError: false,
      );
    } catch (_) {
      // onRepeatEvent reintentará en 30s
    }
  }

  Future<void> _disconnect() async {
    await _sseSubscription?.cancel();
    _sseSubscription = null;
    _httpClient?.close(force: true);
    _httpClient = null;
  }
}
