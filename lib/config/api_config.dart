class ApiConfig {
  // static const String baseUrl = 'https://api.smartstay.es';
  static const String baseUrl = 'http://10.0.0.33:5019';

  static const String authBaseUrl = '$baseUrl/api/auth';
  static const String reservasBaseUrl = '$baseUrl/api/reserva';
  static const String usuariosBaseUrl = '$baseUrl/api/user';
  static const String dispositivosBaseUrl = '$baseUrl/api/device';

  // static const String pushConfigUrl =
  //     'https://api.smartstay.es/api/notifications/push-config';

  static const String pushConfigUrl =
    'http://10.0.0.33:5019/api/notifications/push-config';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
}
