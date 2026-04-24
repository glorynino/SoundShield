// ============================================================
//  lib/screens/reset_password_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _formKey   = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _auth      = AuthService();
  bool _loading    = false;
  bool _sent       = false;

  @override
  void dispose() { _emailCtrl.dispose(); super.dispose(); }

  Future<void> _send() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _auth.resetPassword(_emailCtrl.text.trim());
      if (mounted) setState(() => _sent = true);
    } catch (e) {
      if (mounted) {
        showSnackbar(context,
            e.toString().contains('user-not-found')
                ? 'Aucun compte associé à cet email.'
                : 'Erreur. Réessayez.');
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: _sent ? _buildSuccess() : _buildForm(),
        ),
      ),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Center(
            child: Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: AppColors.primary.withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: const Icon(Icons.lock_reset_rounded,
                  color: AppColors.primary, size: 36),
            ),
          ).animate().fadeIn(duration: 500.ms)
              .scale(begin: const Offset(0.8, 0.8)),

          const SizedBox(height: 32),

          Text('Mot de passe\noublié ?',
              style: GoogleFonts.spaceGrotesk(
                  color: AppColors.textPrimary,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.2))
              .animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),

          const SizedBox(height: 12),

          Text(
            'Entrez votre email, nous vous enverrons\nun lien pour réinitialiser votre mot de passe.',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          ).animate().fadeIn(delay: 150.ms),

          const SizedBox(height: 40),

          AuthTextField(
            label: 'ADRESSE EMAIL',
            hint: 'exemple@email.com',
            controller: _emailCtrl,
            keyboardType: TextInputType.emailAddress,
            prefixIcon: Icons.email_outlined,
            validator: (v) {
              if (v == null || v.trim().isEmpty) return 'Champ requis';
              if (!v.contains('@')) return 'Email invalide';
              return null;
            },
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

          const SizedBox(height: 32),

          AuthButton(
            label: 'ENVOYER LE LIEN',
            onPressed: _send,
            isLoading: _loading,
          ).animate().fadeIn(delay: 250.ms),
        ],
      ),
    );
  }

  Widget _buildSuccess() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const SizedBox(height: 80),
        Container(
          width: 96, height: 96,
          decoration: BoxDecoration(
            color: AppColors.accent.withOpacity(0.15),
            shape: BoxShape.circle,
            border: Border.all(color: AppColors.accent.withOpacity(0.4)),
          ),
          child: const Icon(Icons.mark_email_read_outlined,
              color: AppColors.accent, size: 48),
        ).animate().fadeIn(duration: 600.ms)
            .scale(begin: const Offset(0.5, 0.5)),

        const SizedBox(height: 32),

        Text('Email envoyé !',
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary,
                fontSize: 26,
                fontWeight: FontWeight.w800),
            textAlign: TextAlign.center)
            .animate().fadeIn(delay: 200.ms),

        const SizedBox(height: 12),

        Text(
          'Vérifiez votre boîte mail\n${_emailCtrl.text.trim()}\net suivez les instructions.',
          style: GoogleFonts.spaceGrotesk(
              color: AppColors.textSecondary, fontSize: 14, height: 1.6),
          textAlign: TextAlign.center,
        ).animate().fadeIn(delay: 300.ms),

        const SizedBox(height: 48),

        AuthButton(
          label: 'RETOUR À LA CONNEXION',
          onPressed: () => Navigator.pop(context),
        ).animate().fadeIn(delay: 400.ms),
      ],
    );
  }
}