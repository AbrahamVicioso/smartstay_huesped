import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class NtfyPushConfig {
  final String topic;
  final String ntfyBaseUrl;
  final String? ntfyToken;

  NtfyPushConfig({
    required this.topic,
    required this.ntfyBaseUrl,
    this.ntfyToken,
  });

  factory NtfyPushConfig.fromJson(Map<String, dynamic> json) {
    return NtfyPushConfig(
      topic: json['topic'] as String,
      ntfyBaseUrl: json['ntfyBaseUrl'] as String,
      ntfyToken: json['ntfyToken'] as String?,
    );
  }
}

class NtfyMessage {
  final String id;
  final String topic;
  final String title;
  final String message;
  final DateTime time;
  final List<String> tags;

  NtfyMessage({
    required this.id,
    required this.topic,
    required this.title,
    required this.message,
    required this.time,
    required this.tags,
  });

  factory NtfyMessage.fromJson(Map<String, dynamic> json) {
    return NtfyMessage(
      id: json['id'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      title: json['title'] as String? ?? 'SmartStay',
      message: json['message'] as String? ?? '',
      time: DateTime.fromMillisecondsSinceEpoch(
        ((json['time'] as num?)?.toInt() ?? 0) * 1000,
      ),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>() ?? [],
    );
  }
}

class NtfyService {
  StreamSubscription<String>? _subscription;
  HttpClient? _httpClient;
  final StreamController<NtfyMessage> _messageController =
      StreamController<NtfyMessage>.broadcast();

  Stream<NtfyMessage> get messages => _messageController.stream;
  bool get isConnected => _subscription != null;

  Future<NtfyPushConfig?> fetchConfig(String accessToken) async {
    try {
      final response = await http.get(
        Uri.parse(ApiConfig.pushConfigUrl),
        headers: {'Authorization': 'Bearer $accessToken'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body) as Map<String, dynamic>;
        return NtfyPushConfig.fromJson(json);
      }
      debugPrint('[NtfyService] fetchConfig failed: ${response.statusCode}');
    } catch (e) {
      debugPrint('[NtfyService] fetchConfig error: $e');
    }
    return null;
  }

  Future<void> connect(String accessToken) async {
    await disconnect();

    final config = await fetchConfig(accessToken);
    if (config == null) return;

    final url = Uri.parse('${config.ntfyBaseUrl}/${config.topic}/sse');
    debugPrint('[NtfyService] Connecting SSE to $url');

    try {
      _httpClient = HttpClient();
      _httpClient!.connectionTimeout = const Duration(seconds: 15);

      final ioRequest = await _httpClient!.getUrl(url);
      ioRequest.headers.set('Accept', 'text/event-stream');
      ioRequest.headers.set('Cache-Control', 'no-cache');
      if (config.ntfyToken != null && config.ntfyToken!.isNotEmpty) {
        ioRequest.headers.set('Authorization', 'Bearer ${config.ntfyToken}');
      }

      final ioResponse = await ioRequest.close();
      debugPrint('[NtfyService] SSE connected, status: ${ioResponse.statusCode}');

      String dataBuffer = '';

      _subscription = ioResponse
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
                final msg = NtfyMessage.fromJson(json);
                debugPrint('[NtfyService] SSE message: ${msg.title}');
                _messageController.add(msg);
              }
            } catch (e) {
              debugPrint('[NtfyService] Parse error: $e — data: $dataBuffer');
            } finally {
              dataBuffer = '';
            }
          }
        },
        onError: (e) => debugPrint('[NtfyService] Stream error: $e'),
        onDone: () => debugPrint('[NtfyService] Stream closed'),
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[NtfyService] Connect error: $e');
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    debugPrint('[NtfyService] Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
