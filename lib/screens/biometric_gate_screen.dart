import 'package:flutter/material.dart';
import 'package:mobil_audio_app/services/biometric_service.dart';

class BiometricGateScreen extends StatefulWidget {
  final Widget nextScreen;

  const BiometricGateScreen({super.key, required this.nextScreen});

  @override
  State<BiometricGateScreen> createState() => _BiometricGateScreenState();
}

class _BiometricGateScreenState extends State<BiometricGateScreen> {
  final _biometricService = BiometricService();

  String _statusMessage = 'Vérification en cours...';
  bool _isLoading = true;
  bool _showRetry = false;
  bool _waitingForEnrollment = false;

  @override
  void initState() {
    super.initState();
    _handleBiometricFlow();
  }

  Future<void> _handleBiometricFlow() async {
    setState(() { _isLoading = true; _showRetry = false; });

    // 1. Vérifier si le matériel est dispo
    final hasHardware = await _biometricService.isHardwareAvailable();
    if (!hasHardware) {
      _setStatus('Aucun capteur biométrique détecté sur cet appareil.', showRetry: false);
      // TODO : rediriger vers une auth alternative (PIN, mot de passe)
      return;
    }

    // 2. Vérifier si l'utilisateur a déjà une empreinte dans l'OS
    final hasOsBiometrics = await _biometricService.hasEnrolledBiometrics();

    if (!hasOsBiometrics) {
      // PREMIER LANCEMENT : aucune empreinte dans l'OS → guider l'utilisateur
      _setStatus(
        'Aucune empreinte digitale enregistrée.\nVeuillez en créer une dans les paramètres.',
        loading: false,
      );
      setState(() => _waitingForEnrollment = true);
      return;
    }

    // 3. Empreinte OS existante → lancer l'auth directement
    final bool isAppEnrolled = await _biometricService.isAppEnrolled();

    if (!isAppEnrolled) {
      // Première utilisation de L'APP (mais empreinte OS existante)
      await _biometricService.markAsEnrolled();
    }

    await _authenticate();
  }

  Future<void> _authenticate() async {
    setState(() { _isLoading = true; _showRetry = false; _statusMessage = 'Posez votre doigt...'; });

    final success = await _biometricService.authenticate(
      reason: 'Authentifiez-vous pour accéder à l\'application',
    );

    if (success) {
      // ✅ Succès : naviguer vers l'écran principal
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => widget.nextScreen),
        );
      }
    } else {
      _setStatus('Empreinte non reconnue. Réessayez.', showRetry: true, loading: false);
    }
  }

  Future<void> _openBiometricSettings() async {
    // Ouvre les paramètres de l'OS pour créer une empreinte
    // Option 1 : package url_launcher
    // await launchUrl(Uri.parse('android.settings.SECURITY_SETTINGS'));

    // Option 2 : afficher dialog explicatif
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Créer une empreinte'),
        content: const Text(
          'Allez dans Paramètres → Sécurité → Empreinte digitale '
          'pour enregistrer votre empreinte, puis revenez dans l\'application.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Compris'),
          ),
        ],
      ),
    );

    // Après retour dans l'app : re-vérifier si empreinte créée
    final enrolled = await _biometricService.hasEnrolledBiometrics();
    if (enrolled) {
      setState(() => _waitingForEnrollment = false);
      await _biometricService.markAsEnrolled();
      await _authenticate();
    }
  }

  void _setStatus(String msg, {bool loading = false, bool showRetry = false}) {
    if (mounted) {
      setState(() {
        _statusMessage = msg;
        _isLoading = loading;
        _showRetry = showRetry;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Icône empreinte
                Icon(
                  _waitingForEnrollment
                      ? Icons.fingerprint_outlined
                      : Icons.fingerprint,
                  size: 96,
                  color: _waitingForEnrollment ? Colors.orange : Colors.white,
                ),
                const SizedBox(height: 32),

                // Message de statut
                Text(
                  _statusMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70, fontSize: 16),
                ),
                const SizedBox(height: 32),

                // Loader
                if (_isLoading)
                  const CircularProgressIndicator(color: Colors.white),

                // Bouton créer empreinte (premier lancement OS)
                if (_waitingForEnrollment)
                  ElevatedButton.icon(
                    onPressed: _openBiometricSettings,
                    icon: const Icon(Icons.settings),
                    label: const Text('Configurer l\'empreinte'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),

                // Bouton réessayer (auth échouée)
                if (_showRetry)
                  ElevatedButton.icon(
                    onPressed: _authenticate,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Réessayer'),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}