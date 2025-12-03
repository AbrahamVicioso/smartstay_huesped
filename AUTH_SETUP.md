# Configuración del Sistema de Autenticación

Este documento explica cómo configurar y usar el sistema de autenticación implementado en la aplicación SmartStay.

## Características Implementadas

### 1. Autenticación Completa
- **Login**: Inicio de sesión con email y contraseña
- **Registro**: Creación de nuevas cuentas
- **Recuperación de contraseña**: Solicitud de código por email
- **Reset de contraseña**: Cambio de contraseña con código de verificación
- **Soporte 2FA**: Autenticación de dos factores (opcional)

### 2. Gestión Segura de Tokens
- Almacenamiento seguro con `flutter_secure_storage`
- Refresh automático de tokens expirados
- Interceptores HTTP para agregar tokens automáticamente
- Manejo de expiración con buffer de 5 minutos

### 3. Manejo de Errores
- Errores de validación detallados
- Mensajes de error personalizados por tipo
- Manejo de errores de red y timeouts
- Limpieza automática de sesión en caso de error

## Configuración Inicial

### Paso 1: Instalar Dependencias

```bash
flutter pub get
```

### Paso 2: Configurar URL de la API

Edita el archivo `lib/config/api_config.dart`:

```dart
class ApiConfig {
  // Para desarrollo local:
  // - Android Emulator: 'http://10.0.2.2:7219'
  // - iOS Simulator: 'http://localhost:7219'
  // - Dispositivo físico: 'http://192.168.x.x:7219' (tu IP local)
  // Para producción: 'https://api.tudominio.com'

  static const String baseUrl = 'TU_URL_AQUI';
}
```

### Paso 3: Configurar Permisos (Android)

El almacenamiento seguro ya está configurado, pero para Android asegúrate de tener en `android/app/build.gradle`:

```gradle
android {
    compileSdkVersion 34  // o superior

    defaultConfig {
        minSdkVersion 21  // mínimo requerido
    }
}
```

### Paso 4: Configurar Permisos (iOS)

Para iOS, asegúrate de tener en `ios/Podfile`:

```ruby
platform :ios, '12.0'  # o superior
```

## Estructura del Código

### Modelos de Autenticación

```
lib/models/auth/
├── login_request.dart           # Modelo para login
├── register_request.dart        # Modelo para registro
├── access_token_response.dart   # Respuesta con tokens
├── forgot_password_request.dart # Solicitud de recuperación
├── reset_password_request.dart  # Reset de contraseña
└── auth_exception.dart          # Excepciones personalizadas
```

### Servicios

```
lib/services/
├── api_service.dart              # Cliente HTTP con Dio
├── secure_storage_service.dart   # Almacenamiento seguro
└── auth_provider.dart            # Provider de autenticación
```

### Pantallas

```
lib/screens/
├── login_screen.dart             # Pantalla de login
├── register_screen.dart          # Pantalla de registro
├── forgot_password_screen.dart   # Recuperar contraseña
└── reset_password_screen.dart    # Resetear contraseña
```

## Uso del Sistema

### 1. Iniciar Sesión

```dart
final authProvider = Provider.of<AuthProvider>(context, listen: false);

final success = await authProvider.login(
  'usuario@ejemplo.com',
  'contraseña123',
);

if (success) {
  // Usuario autenticado
  Navigator.of(context).pushReplacementNamed('/home');
} else {
  // Mostrar error
  print(authProvider.errorMessage);
}
```

### 2. Registrarse

```dart
final success = await authProvider.register(
  'nuevo@ejemplo.com',
  'Contraseña123!',
);

if (success) {
  // Registro exitoso, revisar email
}
```

### 3. Recuperar Contraseña

```dart
// Paso 1: Solicitar código
final success = await authProvider.forgotPassword('usuario@ejemplo.com');

// Paso 2: Resetear con código
if (success) {
  await authProvider.resetPassword(
    'usuario@ejemplo.com',
    'CODIGO_RECIBIDO',
    'NuevaContraseña123!',
  );
}
```

### 4. Verificar Estado de Autenticación

```dart
final authProvider = Provider.of<AuthProvider>(context);

if (authProvider.isAuthenticated) {
  // Usuario autenticado
  final user = authProvider.usuario;
  print('Usuario: ${user?.email}');
}
```

### 5. Cerrar Sesión

```dart
await authProvider.logout();
Navigator.of(context).pushReplacementNamed('/login');
```

## Validaciones Implementadas

### Email
- No vacío
- Contiene '@' y '.'
- Formato válido

### Contraseña
- Mínimo 8 caracteres
- Al menos una mayúscula
- Al menos una minúscula
- Al menos un número

### Seguridad
- Tokens almacenados de forma segura
- Refresh automático antes de expiración
- Limpieza de datos en logout
- Manejo de sesiones caducadas

## Personalización

### Cambiar Requisitos de Contraseña

Edita los validators en `register_screen.dart` y `reset_password_screen.dart`:

```dart
validator: (value) {
  if (value.length < 8) {
    return 'Mínimo 8 caracteres';
  }
  // Agrega más reglas según necesites
  return null;
}
```

### Personalizar Mensajes de Error

Edita `auth_exception.dart`:

```dart
@override
String toString() {
  // Personaliza el formato de los mensajes
  return message;
}
```

### Agregar Más Endpoints

En `api_service.dart`:

```dart
Future<ResponseType> nuevoEndpoint() async {
  try {
    final response = await _dio.post('/tu-endpoint');
    return ResponseType.fromJson(response.data);
  } on DioException catch (e) {
    throw _handleDioError(e);
  }
}
```

## Solución de Problemas

### Error de Conexión

1. Verifica que la URL en `api_config.dart` sea correcta
2. Para Android Emulator, usa `10.0.2.2` en lugar de `localhost`
3. Para dispositivo físico, usa la IP de tu máquina

### Error de Certificado SSL (Development)

Si usas HTTPS local sin certificado válido, puedes deshabilitar la verificación SSL en desarrollo (NO RECOMENDADO PARA PRODUCCIÓN):

```dart
// En api_service.dart
(_dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate =
  (client) {
    client.badCertificateCallback =
      (X509Certificate cert, String host, int port) => true;
    return client;
  };
```

### Tokens No Se Guardan

1. Verifica permisos en AndroidManifest.xml
2. Verifica que `flutter_secure_storage` esté correctamente instalado
3. Limpia y reconstruye: `flutter clean && flutter pub get`

## Testing

Para probar el sistema:

1. Inicia tu servidor API
2. Configura la URL correcta en `api_config.dart`
3. Ejecuta la app: `flutter run`
4. Prueba el flujo completo:
   - Registro de usuario
   - Confirmación de email (si aplica)
   - Login
   - Navegación autenticada
   - Recuperación de contraseña
   - Logout

## Producción

Antes de publicar:

1. Cambia `baseUrl` a tu servidor de producción
2. Habilita ofuscación de código
3. Verifica certificados SSL
4. Implementa rate limiting en el backend
5. Configura timeout adecuados
6. Habilita logging solo en debug

## Soporte

Si encuentras problemas:

1. Verifica los logs de la consola
2. Revisa la respuesta del servidor en el interceptor de Dio
3. Verifica que la API esté funcionando con Postman/Insomnia
4. Asegúrate de que los modelos coincidan con la respuesta de la API
