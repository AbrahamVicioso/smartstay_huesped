import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
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
  HttpClientResponse? _response;
  final StreamController<NtfyMessage> _messageController =
      StreamController<NtfyMessage>.broadcast();

  Stream<NtfyMessage> get messages => _messageController.stream;
  bool get isConnected => _subscription != null;

  Future<NtfyPushConfig?> fetchConfig(String accessToken) async {
    try {
      final client = HttpClient()
        ..badCertificateCallback = (_, __, ___) => true;

      final request = await client.getUrl(Uri.parse(ApiConfig.pushConfigUrl));
      request.headers.set('Authorization', 'Bearer $accessToken');
      final response = await request.close();

      if (response.statusCode == 200) {
        final body = await response.transform(utf8.decoder).join();
        final json = jsonDecode(body) as Map<String, dynamic>;
        client.close();
        return NtfyPushConfig.fromJson(json);
      }
      client.close();
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

    final effectiveBase = ApiConfig.ntfyBaseUrlOverride ?? config.ntfyBaseUrl;
    // Use /json stream — one JSON object per line, more reliable than SSE
    final url = Uri.parse('$effectiveBase/${config.topic}/json');
    debugPrint('[NtfyService] Connecting JSON stream to $url');

    try {
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 15)
        ..idleTimeout = const Duration(hours: 24)
        ..badCertificateCallback = (_, __, ___) => true;

      final ioRequest = await _httpClient!.getUrl(url);
      ioRequest.headers.set('Cache-Control', 'no-cache');
      ioRequest.persistentConnection = true;
      if (config.ntfyToken != null && config.ntfyToken!.isNotEmpty) {
        ioRequest.headers.set('Authorization', 'Bearer ${config.ntfyToken}');
      }

      _response = await ioRequest.close();
      debugPrint('[NtfyService] Connected, status: ${_response!.statusCode}');

      _subscription = _response!
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
        (line) {
          if (line.trim().isEmpty) return;
          debugPrint('[NtfyService] JSON line: $line');
          try {
            final json = jsonDecode(line) as Map<String, dynamic>;
            final event = json['event'] as String? ?? '';
            if (event == 'message') {
              final msg = NtfyMessage.fromJson(json);
              debugPrint('[NtfyService] Message: ${msg.title} - ${msg.message}');
              _messageController.add(msg);
            } else {
              debugPrint('[NtfyService] Event: $event');
            }
          } catch (e) {
            debugPrint('[NtfyService] Parse error: $e — line: $line');
          }
        },
        onError: (e) => debugPrint('[NtfyService] Stream error: $e'),
        onDone: () {
          debugPrint('[NtfyService] Stream closed');
          _subscription = null;
        },
        cancelOnError: false,
      );
    } catch (e) {
      debugPrint('[NtfyService] Connect error: $e');
    }
  }

  Future<void> disconnect() async {
    await _subscription?.cancel();
    _subscription = null;
    _response = null;
    _httpClient?.close(force: true);
    _httpClient = null;
    debugPrint('[NtfyService] Disconnected');
  }

  void dispose() {
    disconnect();
    _messageController.close();
  }
}
