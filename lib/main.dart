import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_fonts/google_fonts.dart';
import 'firebase_options.dart';
import 'screens/biometric_gate_screen.dart';
import 'screens/home_screens.dart';
import 'screens/login_screen.dart';
import 'widgets/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();       
  await Firebase.initializeApp(                     
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Audio App',
      debugShowCheckedModeBanner: false,
      theme: ThemeData.dark().copyWith(              // garde le dark theme du binôme
        textTheme: GoogleFonts.spaceGroteskTextTheme(
          ThemeData.dark().textTheme,
        ),
      ),
      // ➊ Démarre sur BiometricGateScreen (code binôme intact ✅)
      // ➋ Après empreinte validée → AuthGate gère login/home
      home: BiometricGateScreen(nextScreen: const AuthGate()),  // ← seul changement
    );
  }
}

/// Redirige automatiquement selon l'état Firebase :
///   connecté    → HomeScreen
///   non connecté → LoginScreen
class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppColors.background,
            body: Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),
          );
        }
        if (snapshot.hasData) return const HomeScreen();   // connecté
        return const LoginScreen();                        // non connecté
      },
    );
  }
}
