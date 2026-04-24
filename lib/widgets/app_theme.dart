// ============================================================
//  lib/widgets/app_theme.dart
//  Palette de couleurs + widgets réutilisables pour toute l'app
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppColors {
  static const background   = Color(0xFF0A0A0F);
  static const surface      = Color(0xFF13131A);
  static const card         = Color(0xFF1C1C26);
  static const primary      = Color(0xFF6C63FF);
  static const primaryLight = Color(0xFF9D97FF);
  static const accent       = Color(0xFF00E5A0);
  static const textPrimary  = Color(0xFFF0F0FF);
  static const textSecondary= Color(0xFF8888AA);
  static const error        = Color(0xFFFF6B8A);
  static const border       = Color(0xFF2A2A3A);
}

// ─── Champ de texte stylisé ───────────────────────────────────────────────────
class AuthTextField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;

  const AuthTextField({
    super.key,
    required this.label,
    this.hint,
    required this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
  });

  @override
  State<AuthTextField> createState() => _AuthTextFieldState();
}

class _AuthTextFieldState extends State<AuthTextField> {
  bool _obscure = true;
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      onFocusChange: (v) => setState(() => _focused = v),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.label,
            style: GoogleFonts.spaceGrotesk(
              color: _focused ? AppColors.primaryLight : AppColors.textSecondary,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 1.2,
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: widget.controller,
            obscureText: widget.isPassword ? _obscure : false,
            keyboardType: widget.keyboardType,
            validator: widget.validator,
            style: GoogleFonts.spaceGrotesk(
                color: AppColors.textPrimary, fontSize: 15),
            decoration: InputDecoration(
              hintText: widget.hint,
              hintStyle: GoogleFonts.spaceGrotesk(
                color: AppColors.textSecondary.withOpacity(0.5),
                fontSize: 14,
              ),
              filled: true,
              fillColor: AppColors.card,
              prefixIcon: widget.prefixIcon != null
                  ? Icon(widget.prefixIcon,
                      color: _focused
                          ? AppColors.primary
                          : AppColors.textSecondary,
                      size: 20)
                  : null,
              suffixIcon: widget.isPassword
                  ? IconButton(
                      icon: Icon(
                        _obscure ? Icons.visibility_off : Icons.visibility,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      onPressed: () => setState(() => _obscure = !_obscure),
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 1.5),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error),
              ),
              focusedErrorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.error, width: 1.5),
              ),
              errorStyle: GoogleFonts.spaceGrotesk(
                  color: AppColors.error, fontSize: 11),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Bouton principal ─────────────────────────────────────────────────────────
class AuthButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final bool outlined;

  const AuthButton({
    super.key,
    required this.label,
    this.onPressed,
    this.isLoading = false,
    this.outlined = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: outlined
          ? OutlinedButton(
              onPressed: isLoading ? null : onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primary),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: _child(),
            )
          : ElevatedButton(
              onPressed: isLoading ? null : onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor: AppColors.primary.withOpacity(0.5),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: _child(),
            ),
    );
  }

  Widget _child() {
    if (isLoading) {
      return const SizedBox(
        width: 22, height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2.5,
          valueColor: AlwaysStoppedAnimation(Colors.white),
        ),
      );
    }
    return Text(
      label,
      style: GoogleFonts.spaceGrotesk(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.5,
        color: outlined ? AppColors.primary : Colors.white,
      ),
    );
  }
}

// ─── Snackbar helper ──────────────────────────────────────────────────────────
void showSnackbar(BuildContext context, String message, {bool isError = true}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message,
          style: GoogleFonts.spaceGrotesk(color: Colors.white)),
      backgroundColor: isError ? AppColors.error : AppColors.accent,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      margin: const EdgeInsets.all(16),
    ),
  );
}