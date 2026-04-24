// ============================================================
//  lib/screens/register_screen.dart
// ============================================================

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/app_theme.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey       = GlobalKey<FormState>();
  final _nomCtrl       = TextEditingController();
  final _prenomCtrl    = TextEditingController();
  final _emailCtrl     = TextEditingController();
  final _passCtrl      = TextEditingController();
  final _confirmCtrl   = TextEditingController();
  final _auth          = AuthService();

  DateTime? _dob;
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose(); _prenomCtrl.dispose();
    _emailCtrl.dispose(); _passCtrl.dispose(); _confirmCtrl.dispose();
    super.dispose();
  }

  int? get _age {
    if (_dob == null) return null;
    final now = DateTime.now();
    int a = now.year - _dob!.year;
    if (now.month < _dob!.month ||
        (now.month == _dob!.month && now.day < _dob!.day)) a--;
    return a;
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(DateTime.now().year - 16),
      firstDate: DateTime(1920),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: ThemeData.dark().copyWith(
          colorScheme: const ColorScheme.dark(
              primary: AppColors.primary, surface: AppColors.card),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;
    if (_dob == null) {
      showSnackbar(context, 'Veuillez sélectionner votre date de naissance.');
      return;
    }
    if (_age! < 13) {
      showSnackbar(context, 'Vous devez avoir au moins 13 ans.');
      return;
    }
    setState(() => _loading = true);
    try {
      await _auth.register(
        email: _emailCtrl.text.trim(),
        password: _passCtrl.text,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        dateNaissance: _dob!,
      );
      if (mounted) {
        showSnackbar(context, 'Compte créé avec succès !', isError: false);
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, _errMsg(e.toString()));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _errMsg(String e) {
    if (e.contains('email-already-in-use')) return 'Cet email est déjà utilisé.';
    if (e.contains('weak-password')) return 'Mot de passe trop faible.';
    if (e.contains('age_invalid')) return 'Vous devez avoir au moins 13 ans.';
    return 'Erreur lors de l\'inscription. Réessayez.';
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
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Créer un compte',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textPrimary,
                        fontSize: 30,
                        fontWeight: FontWeight.w800))
                    .animate().fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 6),
                Text('Rejoignez-nous dès maintenant',
                    style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary, fontSize: 14))
                    .animate().fadeIn(delay: 80.ms),

                const SizedBox(height: 32),

                // Nom & Prénom
                Row(children: [
                  Expanded(
                    child: AuthTextField(
                      label: 'NOM',
                      hint: 'Dupont',
                      controller: _nomCtrl,
                      prefixIcon: Icons.person_outline_rounded,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: AuthTextField(
                      label: 'PRÉNOM',
                      hint: 'Jean',
                      controller: _prenomCtrl,
                      prefixIcon: Icons.badge_outlined,
                      validator: (v) =>
                          (v == null || v.trim().isEmpty) ? 'Requis' : null,
                    ),
                  ),
                ]).animate().fadeIn(delay: 120.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // Date de naissance
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DATE DE NAISSANCE',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2)),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: (_dob != null && _age! < 13)
                                ? AppColors.error
                                : AppColors.border,
                          ),
                        ),
                        child: Row(children: [
                          Icon(Icons.calendar_today_outlined,
                              color: _dob != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20),
                          const SizedBox(width: 12),
                          Text(
                            _dob == null
                                ? 'Sélectionner une date'
                                : '${_dob!.day.toString().padLeft(2, '0')}/'
                                    '${_dob!.month.toString().padLeft(2, '0')}/'
                                    '${_dob!.year}',
                            style: GoogleFonts.spaceGrotesk(
                              color: _dob == null
                                  ? AppColors.textSecondary.withOpacity(0.5)
                                  : AppColors.textPrimary,
                              fontSize: 15,
                            ),
                          ),
                          const Spacer(),
                          if (_dob != null)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: _age! >= 13
                                    ? AppColors.accent.withOpacity(0.15)
                                    : AppColors.error.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text('$_age ans',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: _age! >= 13
                                        ? AppColors.accent
                                        : AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  )),
                            ),
                        ]),
                      ),
                    ),
                    if (_dob != null && _age! < 13)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text('Vous devez avoir au moins 13 ans',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.error, fontSize: 11)),
                      ),
                  ],
                ).animate().fadeIn(delay: 160.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

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

                const SizedBox(height: 20),

                AuthTextField(
                  label: 'MOT DE PASSE',
                  hint: '••••••••',
                  controller: _passCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ).animate().fadeIn(delay: 240.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                AuthTextField(
                  label: 'CONFIRMER LE MOT DE PASSE',
                  hint: '••••••••',
                  controller: _confirmCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v != _passCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 280.ms).slideY(begin: 0.1),

                const SizedBox(height: 36),

                AuthButton(
                  label: "S'INSCRIRE",
                  onPressed: _register,
                  isLoading: _loading,
                ).animate().fadeIn(delay: 320.ms),

                const SizedBox(height: 16),

                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style: GoogleFonts.spaceGrotesk(
                            color: AppColors.textSecondary, fontSize: 13),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: GoogleFonts.spaceGrotesk(
                                color: AppColors.primaryLight,
                                fontWeight: FontWeight.w700),
                          ),
                        ],
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 360.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}