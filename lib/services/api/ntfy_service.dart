import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';

class NtfyPushConfig {
  final String topic;
  final String ntfyBaseUrl;
  final String ntfyToken;

  NtfyPushConfig({
    required this.topic,
    required this.ntfyBaseUrl,
    required this.ntfyToken,
  });

  factory NtfyPushConfig.fromJson(Map<String, dynamic> json) {
    return NtfyPushConfig(
      topic: json['topic'] as String,
      ntfyBaseUrl: json['ntfyBaseUrl'] as String,
      ntfyToken: json['ntfyToken'] as String,
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

    final url = Uri.parse('${config.ntfyBaseUrl}/${config.topic}/json');
    debugPrint('[NtfyService] Connecting to $url');

    try {
      final client = http.Client();
      final request = http.Request('GET', url);
      request.headers['Authorization'] = 'Bearer ${config.ntfyToken}';

      final streamedResponse = await client.send(request);

      _subscription = streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isEmpty) return;
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            if (json['event'] == 'message') {
              final msg = NtfyMessage.fromJson(json);
              debugPrint('[NtfyService] Message received: ${msg.title}');
              _messageController.add(msg);
            }
          } catch (e) {
            debugPrint('[NtfyService] Parse error: $e');
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
    debugPrint('[NtfyService] Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
