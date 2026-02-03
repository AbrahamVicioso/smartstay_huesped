# SmartStay - Aplicación para Huéspedes

Aplicación móvil Flutter para huéspedes de hotel que permite una experiencia sin contacto con check-in digital, gestión de actividades, notificaciones y más.

## Características Implementadas

### 1. Autenticación y Seguridad
- Login con email y contraseña
- Validación de campos
- Almacenamiento seguro con SharedPreferences
- Splash screen con animaciones

### 2. Check-in Digital
- Proceso paso a paso (Stepper)
- Registro de datos personales
- Validación de número de reserva
- Generación automática de PIN de 6 dígitos
- Visualización de información de habitación

### 3. Dashboard Principal
- **Sección "Mis Habitaciones"** con:
  - Lista de habitaciones registradas
  - Botón "Abrir" en cada habitación
  - Información: número, tipo, estado, PIN
  - Contador de habitaciones activas
- **Sistema de Apertura de Puertas**:
  - Apertura Remota (WiFi)
  - Apertura con NFC (con animaciones)
  - Visualización de PIN
- Accesos rápidos a servicios
- Servicios destacados

### 4. Sistema de Notificaciones
- Notificaciones de acceso de personal
- Notificaciones de recordatorios
- Sistema de lectura/no lectura
- Deslizar para eliminar
- Configuración de notificaciones
- Modo "No Molestar" con horarios personalizados

### 5. Gestión de Actividades
- Catálogo de actividades:
  - Gimnasio
  - Spa & Wellness
  - Restaurante Gourmet
  - Piscina Infinity
  - Tours
  - Clases de Yoga
- Filtrado por categorías
- Información detallada:
  - Horarios
  - Capacidad
  - Precios
  - Requisitos de reserva
- Sistema de reservas con calendario
- Selección de hora y número de personas
- Gestión de mis reservas
- Cancelación de reservas

### 6. Perfil y Configuración
- Visualización de información personal
- Información de estadía actual
- Cambio de idioma (Español/Inglés)
- Configuración de notificaciones
- Modo "No Molestar"
- Cerrar sesión

## Diseño

### Paleta de Colores
- **Primary**: #1A1A2E (Azul oscuro sofisticado)
- **Secondary**: #0F3460 (Azul medio)
- **Accent**: #E94560 (Rosa/rojo elegante)
- **Gold**: #D4AF37 (Dorado)
- **Background**: #F8F9FA (Gris claro)

### Tipografía
- **Títulos**: Playfair Display (elegante)
- **Cuerpo**: Poppins (moderna y legible)

### Componentes
- Cards con sombras suaves
- Botones con bordes redondeados
- Inputs con estilo Material Design 3
- Bottom Navigation Bar
- Animaciones fluidas

## Estructura del Proyecto

```
lib/
├── main.dart                 # Punto de entrada y configuración
├── theme/
│   └── app_theme.dart       # Tema y estilos personalizados
├── models/
│   ├── user.dart            # Modelo de usuario
│   ├── reserva.dart         # Modelo de reserva
│   ├── actividad.dart       # Modelos de actividades
│   └── notificacion.dart    # Modelo de notificación
├── services/
│   ├── auth_provider.dart           # Gestión de autenticación
│   ├── actividades_provider.dart    # Gestión de actividades
│   └── notificaciones_provider.dart # Gestión de notificaciones
├── widgets/
│   ├── habitacion_card.dart         # Tarjeta de habitación con botón abrir
│   ├── apertura_opciones_sheet.dart # BottomSheet con opciones de apertura
│   ├── apertura_nfc_modal.dart      # Modal animado para NFC
│   ├── apertura_remota_modal.dart   # Modal para apertura remota
│   └── apertura_pin_modal.dart      # Modal para mostrar PIN
└── screens/
    ├── login_screen.dart         # Pantalla de login
    ├── checkin_screen.dart       # Check-in digital
    ├── home_screen.dart          # Dashboard principal
    ├── actividades_screen.dart   # Gestión de actividades
    ├── notificaciones_screen.dart # Notificaciones
    └── perfil_screen.dart        # Perfil y configuración
```

## Instalación y Configuración

### Requisitos
- Flutter SDK 3.8.1 o superior
- Dart SDK compatible
- Android Studio / VS Code
- Dispositivo Android 9.0+ o iOS 13.0+

### Pasos de Instalación

1. **Instalar dependencias**
   ```bash
   flutter pub get
   ```

2. **Ejecutar en modo debug**
   ```bash
   flutter run
   ```

3. **Compilar para producción**

   Android:
   ```bash
   flutter build apk --release
   ```

   iOS:
   ```bash
   flutter build ios --release
   ```

## Dependencias Principales

- **provider**: Manejo de estado
- **google_fonts**: Fuentes personalizadas
- **flutter_svg**: Soporte para SVG
- **shared_preferences**: Almacenamiento local
- **intl**: Internacionalización
- **table_calendar**: Calendario para reservas
- **flutter_local_notifications**: Notificaciones locales

## Datos de Prueba

Para probar la aplicación, puedes usar cualquier email y contraseña (mínimo 6 caracteres).

### Ejemplo:
- Email: `demo@smartstay.com`
- Contraseña: `123456`
- Número de Reserva: `RES-2024-001234`

## Funcionalidades Adicionales

### ✅ Sistema de Apertura de Habitaciones (NUEVO)
- Gestión de habitaciones desde el dashboard
- Tres métodos de apertura:
  - 🌐 **Apertura Remota**: Conecta vía WiFi con animaciones
  - 📱 **Apertura NFC**: Ondas expansivas y llave animada
  - 🔢 **PIN de Acceso**: Visualización y copia de código
- Animaciones premium en cada método
- BottomSheet con opciones
- Modales con feedback visual

## Funcionalidades Futuras (No Implementadas)

- ❌ Conexión real con BLE a cerraduras físicas
- ❌ Integración con API backend real
- ❌ Pagos integrados
- ❌ Chat en tiempo real con recepción
- ❌ Mapas del hotel
- ❌ Integración con servicios de terceros

## Capturas de Pantalla

La aplicación cuenta con:
- Splash screen animado
- Login elegante con validación
- Check-in paso a paso
- Dashboard moderno con tarjetas
- Sistema completo de notificaciones
- Gestión de actividades con filtros
- Perfil personalizable

## Notas de Desarrollo

- Todos los datos son simulados (mock data)
- Las operaciones tienen delays artificiales para simular llamadas a API
- El PIN se genera aleatoriamente basado en el timestamp
- La aplicación usa Provider para manejo de estado reactivo
- Diseño responsive que se adapta a diferentes tamaños de pantalla

## Autor

Desarrollado con Flutter para la gestión inteligente de huéspedes en hoteles.

## Licencia

Este es un proyecto educativo/prototipo.
