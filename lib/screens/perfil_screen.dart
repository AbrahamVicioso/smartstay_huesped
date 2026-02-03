import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/auth_provider.dart';
import '../services/notificaciones_provider.dart';
import '../theme/app_theme.dart';

class PerfilScreen extends StatelessWidget {
  const PerfilScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final usuario = authProvider.usuario;
    final reserva = authProvider.reservaActual;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mi Perfil'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () async {
              final confirmado = await _confirmarLogout(context);
              if (confirmado && context.mounted) {
                await authProvider.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacementNamed('/login');
                }
              }
            },
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Avatar y nombre
            CircleAvatar(
              radius: 50,
              backgroundColor: AppTheme.primaryColor,
              child: Text(
                usuario?.nombre.substring(0, 1).toUpperCase() ?? 'U',
                style: const TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              usuario?.nombre ?? 'Usuario',
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 4),
            Text(
              usuario?.email ?? '',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),

            const SizedBox(height: 32),

            // Información de la reserva
            if (reserva != null) ...[
              _SeccionCard(
                titulo: 'Información de Estadía',
                children: [
                  _InfoTile(
                    icono: Icons.hotel,
                    titulo: 'Habitación',
                    valor: '${reserva.numeroHabitacion} - ${reserva.tipoHabitacion}',
                  ),
                  _InfoTile(
                    icono: Icons.confirmation_number,
                    titulo: 'Número de Reserva',
                    valor: reserva.numeroReserva,
                  ),
                  _InfoTile(
                    icono: Icons.vpn_key,
                    titulo: 'PIN de Acceso',
                    valor: reserva.pinAcceso,
                    trailing: IconButton(
                      icon: const Icon(Icons.copy, size: 20),
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('PIN copiado al portapapeles'),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
            ],

            // Información personal
            _SeccionCard(
              titulo: 'Información Personal',
              children: [
                _InfoTile(
                  icono: Icons.person,
                  titulo: 'Nombre completo',
                  valor: usuario?.nombre ?? '',
                ),
                _InfoTile(
                  icono: Icons.email,
                  titulo: 'Correo electrónico',
                  valor: usuario?.email ?? '',
                ),
                _InfoTile(
                  icono: Icons.phone,
                  titulo: 'Teléfono',
                  valor: usuario?.telefono ?? '',
                ),
                _InfoTile(
                  icono: Icons.language,
                  titulo: 'Idioma',
                  valor: usuario?.idioma == 'es' ? 'Español' : 'English',
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _mostrarSelectorIdioma(context);
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Configuración
            _SeccionCard(
              titulo: 'Configuración',
              children: [
                Consumer<NotificacionesProvider>(
                  builder: (context, notifProvider, child) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: const Text('Notificaciones Push'),
                      subtitle: const Text('Recibir notificaciones en tiempo real'),
                      secondary: const Icon(Icons.notifications_active),
                      value: notifProvider.notificacionesActivas,
                      onChanged: (value) {
                        notifProvider.toggleNotificaciones(value);
                      },
                    );
                  },
                ),
                Consumer<NotificacionesProvider>(
                  builder: (context, notifProvider, child) {
                    return SwitchListTile(
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 4,
                      ),
                      title: const Text('Modo No Molestar'),
                      subtitle: Text(
                        '${notifProvider.horaInicioNoMolestar} - ${notifProvider.horaFinNoMolestar}',
                      ),
                      secondary: const Icon(Icons.do_not_disturb),
                      value: notifProvider.modoNoMolestar,
                      onChanged: (value) {
                        notifProvider.toggleModoNoMolestar(value);
                      },
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Otras opciones
            _SeccionCard(
              titulo: 'Otros',
              children: [
                ListTile(
                  leading: const Icon(Icons.help_outline),
                  title: const Text('Ayuda y Soporte'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Contacte a recepción para asistencia'),
                      ),
                    );
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.info_outline),
                  title: const Text('Acerca de'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    _mostrarAcercaDe(context);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.privacy_tip_outlined),
                  title: const Text('Privacidad y Términos'),
                  trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                  onTap: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Funcionalidad en desarrollo'),
                      ),
                    );
                  },
                ),
              ],
            ),

            const SizedBox(height: 32),

            // Versión
            Text(
              'Versión 1.0.0',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppTheme.textSecondary,
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<bool> _confirmarLogout(BuildContext context) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Cerrar Sesión'),
            content: const Text('¿Está seguro que desea cerrar sesión?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accentColor,
                ),
                child: const Text('Cerrar Sesión'),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _mostrarSelectorIdioma(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Seleccionar Idioma'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Text('🇪🇸', style: TextStyle(fontSize: 24)),
              title: const Text('Español'),
              onTap: () async {
                final nuevoUsuario = authProvider.usuario!.copyWith(idioma: 'es');
                await authProvider.actualizarPerfil(nuevoUsuario);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Idioma actualizado')),
                  );
                }
              },
            ),
            ListTile(
              leading: const Text('🇺🇸', style: TextStyle(fontSize: 24)),
              title: const Text('English'),
              onTap: () async {
                final nuevoUsuario = authProvider.usuario!.copyWith(idioma: 'en');
                await authProvider.actualizarPerfil(nuevoUsuario);
                if (context.mounted) {
                  Navigator.of(context).pop();
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Language updated')),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarAcercaDe(BuildContext context) {
    showAboutDialog(
      context: context,
      applicationName: 'SmartStay',
      applicationVersion: '1.0.0',
      applicationIcon: const Icon(
        Icons.hotel,
        size: 48,
        color: AppTheme.primaryColor,
      ),
      children: [
        const Text(
          'SmartStay es tu compañero perfecto para una estadía sin complicaciones. '
          'Gestiona tu check-in, accede a tu habitación digitalmente, '
          'reserva actividades y mantente informado en todo momento.',
        ),
        const SizedBox(height: 16),
        const Text(
          'Desarrollado con Flutter para Android e iOS.',
        ),
      ],
    );
  }
}

class _SeccionCard extends StatelessWidget {
  final String titulo;
  final List<Widget> children;

  const _SeccionCard({
    required this.titulo,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              titulo,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                color: AppTheme.primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
            const Divider(),
            ...children,
          ],
        ),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final IconData icono;
  final String titulo;
  final String valor;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _InfoTile({
    required this.icono,
    required this.titulo,
    required this.valor,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: 4),
      leading: Icon(icono, color: AppTheme.primaryColor),
      title: Text(
        titulo,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: AppTheme.textSecondary,
        ),
      ),
      subtitle: Text(
        valor,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      trailing: trailing,
      onTap: onTap,
    );
  }
}
