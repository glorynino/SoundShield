import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

class BiometricService {
  static const _enrolledKey = 'biometric_enrolled';
  final LocalAuthentication _auth = LocalAuthentication();

  /// Vérifie si le matériel biométrique est disponible
  Future<bool> isHardwareAvailable() async {
    return await _auth.canCheckBiometrics || await _auth.isDeviceSupported();
  }

  /// Vérifie si une empreinte a déjà été enregistrée dans l'OS
  Future<bool> hasEnrolledBiometrics() async {
    final biometrics = await _auth.getAvailableBiometrics();
    return biometrics.isNotEmpty;
  }

  /// Vérifie si l'utilisateur a déjà passé l'étape d'enrôlement dans l'app
  Future<bool> isAppEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_enrolledKey) ?? false;
  }

  /// Sauvegarde que l'enrôlement est fait
  Future<void> markAsEnrolled() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_enrolledKey, true);
  }

  /// Lance l'authentification biométrique
  Future<bool> authenticate({String reason = 'Veuillez scanner votre empreinte'}) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          stickyAuth: true,        // reste actif si app passe en arrière-plan
          biometricOnly: true,     // interdit le fallback PIN/schéma
          useErrorDialogs: true,
        ),
      );
    } catch (e) {
      return false;
    }
  }
}