class ApiConfig {
  //static const String authBaseUrl = 'http://localhost:5117';
  //static const String usuariosBaseUrl = 'http://localhost:5284';
  //static const String reservasBaseUrl = 'http://localhost:5141';

  static const String authBaseUrl = 'http://localhost:5117';
  static const String usuariosBaseUrl = 'http://localhost:5284';
  static const String reservasBaseUrl = 'http://localhost:5141';

  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const String apiVersion = 'v1';
}
