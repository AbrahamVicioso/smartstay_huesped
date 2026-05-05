import 'package:local_auth/local_auth.dart';

class BiometricService {
  static final _auth = LocalAuthentication();

  /// Returns true if auth passed or device has no biometrics configured.
  /// Returns false if user cancelled or failed.
  static Future<bool> authenticate(String reason) async {
    try {
      final isSupported = await _auth.isDeviceSupported();
      if (!isSupported) return true;

      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
