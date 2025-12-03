class ApiConfig {
  // IMPORTANTE: Cambia esta URL por la URL de tu servidor
  // Para desarrollo local en Android Emulator usa: http://10.0.2.2:7219
  // Para desarrollo local en iOS Simulator usa: http://localhost:7219
  // Para dispositivos físicos usa la IP de tu máquina: http://192.168.x.x:7219
  // Para producción usa tu dominio: https://api.tudominio.com

  // URL base para autenticación y gestión de usuarios
  static const String baseUrl = 'http://10.0.2.2:5117';

  // URL base para el sistema de reservas
  // Para desarrollo local en Android Emulator usa: http://10.0.2.2:5141
  // Para producción usa: https://reservas.tudominio.com
  static const String reservasBaseUrl = 'http://10.0.2.2:5141';

  // Configuración de timeouts
  static const Duration connectionTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);

  // Versión de la API (si aplica)
  static const String apiVersion = 'v1';
}
