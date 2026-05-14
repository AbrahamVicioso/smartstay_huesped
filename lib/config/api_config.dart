class ApiConfig {
  static const String baseUrl = 'https://api.smartstay.es';
  // static const String baseUrl = 'http://10.0.0.33:5019';

  static const String authBaseUrl = '$baseUrl/api/auth';
  static const String reservasBaseUrl = '$baseUrl/api/reserva';
  static const String usuariosBaseUrl = '$baseUrl/api/user';
  static const String dispositivosBaseUrl = '$baseUrl/api/device';

  static const String pushConfigUrl = '$baseUrl/api/notifications/push-config';

  // ntfy server URL — override API-returned ntfyBaseUrl when set
  // null = use whatever the API returns in push-config
  static const String? ntfyBaseUrlOverride = 'https://ntfy.smartstay.es';
  // static const String? ntfyBaseUrlOverride = 'http://10.0.0.33:8082';
  // static const String? ntfyBaseUrlOverride = null;

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
