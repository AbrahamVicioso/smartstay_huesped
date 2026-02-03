# Instrucciones Rápidas - SmartStay Huésped

## Pasos para Ejecutar la Aplicación

### 1. Instalar Dependencias
Abre una terminal en la carpeta del proyecto y ejecuta:
```bash
flutter pub get
```

### 2. Verificar Dispositivos Disponibles
```bash
flutter devices
```

### 3. Ejecutar la Aplicación
```bash
flutter run
```

Si tienes varios dispositivos conectados, especifica uno:
```bash
flutter run -d <device_id>
```

Para ejecutar en Chrome (web):
```bash
flutter run -d chrome
```

## Credenciales de Prueba

### Login
- **Email**: cualquier email válido (ej: `demo@smartstay.com`)
- **Contraseña**: cualquier texto de 6+ caracteres (ej: `123456`)

### Check-in
- **Nombre**: Tu nombre
- **Email**: cualquier email válido
- **Teléfono**: cualquier número
- **Número de Reserva**: cualquier texto (ej: `RES-2024-001234`)

## Navegación en la App

### Pantalla de Login
- Ingresa email y contraseña
- O presiona "Realizar Check-in" para check-in directo

### Check-in Digital
- Completa 3 pasos: Datos Personales, Reserva, Confirmación
- Al finalizar recibes un PIN de 6 dígitos

### Dashboard Principal
- **Tab Inicio**: Ver información de habitación y accesos rápidos
- **Tab Actividades**: Explorar y reservar actividades del hotel
- **Tab Notificaciones**: Ver notificaciones de accesos y recordatorios
- **Tab Perfil**: Ver información personal y configuración

### Actividades
- Filtra por categoría (Gimnasio, Spa, Restaurante, etc.)
- Toca una actividad para ver detalles
- Si requiere reserva, selecciona fecha, hora y número de personas
- Gestiona tus reservas desde la parte inferior

### Notificaciones
- Desliza hacia la izquierda para eliminar
- Toca para marcar como leída
- Configura notificaciones con el ícono de ajustes

### Perfil
- Cambia idioma (Español/Inglés)
- Activa/desactiva notificaciones
- Configura modo "No Molestar"
- Cierra sesión

## Características Destacadas

### ✅ Check-in sin contacto
Completa tu check-in digitalmente en menos de 5 minutos.

### ✅ PIN de acceso digital
Recibe un código de 6 dígitos para acceder a tu habitación.

### ✅ Notificaciones en tiempo real
Recibe alertas cuando personal autorizado acceda a tu habitación.

### ✅ Reserva de actividades
Sistema completo con calendario, selección de hora y gestión de reservas.

### ✅ Perfil personalizable
Cambia idioma, configura notificaciones y modo "No Molestar".

### ✅ Diseño elegante
Interfaz moderna con colores sofisticados y animaciones fluidas.

## Solución de Problemas

### Error al ejecutar `flutter pub get`
```bash
flutter clean
flutter pub get
```

### La app no compila
Verifica tu versión de Flutter:
```bash
flutter --version
```
Debe ser 3.8.1 o superior.

### Fuentes no se cargan
Las fuentes de Google se descargan automáticamente. Si hay problemas:
1. Verifica tu conexión a internet
2. Ejecuta `flutter pub get` nuevamente

### Hot reload no funciona
Presiona `r` en la terminal para hot reload, o `R` para hot restart.

## Atajos de Desarrollo

- `r`: Hot reload (recarga rápida)
- `R`: Hot restart (reinicio completo)
- `p`: Mostrar grid de debug
- `o`: Cambiar entre iOS y Android
- `q`: Salir

## Próximos Pasos

Una vez que la app esté funcionando, puedes:
1. Explorar todas las funcionalidades
2. Probar el flujo completo de check-in
3. Reservar varias actividades
4. Configurar notificaciones
5. Cambiar idioma en el perfil

## Notas Importantes

- **Datos simulados**: Todos los datos son de prueba (mock data)
- **Sin backend**: La app funciona sin servidor, ideal para prototipo
- **Sin BLE**: La funcionalidad Bluetooth no está implementada
- **Offline**: Algunas funciones funcionan sin conexión

## Contacto

Para preguntas o problemas con el prototipo, consulta el README.md principal.
