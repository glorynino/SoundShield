// ============================================================
//  lib/screens/favorites_screen.dart
//  Fix : StreamBuilder Firestore isolé du lecteur audio
//  → plus de rechargement en boucle pendant la lecture
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sourate_model.dart';
import '../services/quran_service.dart';
import '../services/biometric_service.dart';
import '../services/audio_controller.dart';
import '../widgets/app_theme.dart';

// Plus besoin de _sharedPlayer → on utilise AudioController.instance
class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _quranService     = QuranService();
  final _biometricService = BiometricService();
  final _ctrl             = AudioController.instance;

  @override
  void initState() {
    super.initState();
    _ctrl.addListener(_onControllerChange);
  }

  @override
  void dispose() {
    _ctrl.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  Future<void> _jouer(Favori f) async {
    try {
      await _ctrl.jouerFavori(f);
    } catch (e) {
      if (mounted) showSnackbar(context, 'Erreur de lecture. Réessayez.');
    }
  }

  // ── Suppression avec empreinte ────────────────────────────────────────────
  Future<void> _supprimerAvecEmpreinte(Favori f) async {
    final hasHardware = await _biometricService.isHardwareAvailable();
    final hasEnrolled = await _biometricService.hasEnrolledBiometrics();

    if (!hasHardware || !hasEnrolled) {
      final confirm = await _showConfirmDialog(f);
      if (confirm == true) await _supprimer(f);
      return;
    }

    final success = await _biometricService.authenticate(
      reason: 'Confirmez la suppression de "${f.nomAnglais}" des favoris',
    );

    if (success) {
      await _supprimer(f);
    } else {
      if (mounted) {
        showSnackbar(context, 'Empreinte non reconnue. Suppression annulée.');
      }
    }
  }

  Future<void> _supprimer(Favori f) async {
    if (_ctrl.titreEnCours == f.nomAnglais) {
      _ctrl.stop();
    }
    await _quranService.supprimerFavori(f.numeroSourate);
    if (mounted) {
      showSnackbar(context, '"${f.nomAnglais}" retiré des favoris.',
          isError: false);
    }
  }

  Future<bool?> _showConfirmDialog(Favori f) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        title: Text('Supprimer le favori',
            style: GoogleFonts.syne(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w700)),
        content: Text(
          'Voulez-vous retirer "${f.nomAnglais}" de vos favoris ?',
          style: GoogleFonts.syne(
              color: AppColors.textSecondary, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Annuler',
                style: GoogleFonts.syne(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text('Supprimer',
                style: GoogleFonts.syne(
                    color: AppColors.error,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            Expanded(
              child: StreamBuilder<List<Favori>>(
                stream: _quranService.getFavorisStream(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                          color: AppColors.primary),
                    );
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text('Erreur de chargement.',
                          style: GoogleFonts.syne(
                              color: AppColors.textSecondary)),
                    );
                  }
                  final favoris = snapshot.data ?? [];
                  if (favoris.isEmpty) return _buildEmptyState();
                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 8),
                    itemCount: favoris.length,
                    itemBuilder: (_, i) => _buildFavoriItem(favoris[i]),
                  );
                },
              ),
            ),
            // Plus de _MiniPlayer ici → GlobalMiniPlayer dans HomeScreen
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Mes Favoris',
              style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 28,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.lock_outline_rounded,
                  color: AppColors.textSecondary, size: 13),
              const SizedBox(width: 4),
              Text('Suppression protégée par empreinte',
                  style: GoogleFonts.syne(
                      color: AppColors.textSecondary, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 80, height: 80,
            decoration: BoxDecoration(
              color: AppColors.card,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.border),
            ),
            child: const Icon(Icons.favorite_border_rounded,
                color: AppColors.textSecondary, size: 36),
          ),
          const SizedBox(height: 20),
          Text('Aucun favori pour l\'instant',
              style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text(
            'Ajoutez des sourates depuis\nle lecteur audio',
            textAlign: TextAlign.center,
            style: GoogleFonts.syne(
                color: AppColors.textSecondary, fontSize: 13),
          ),
        ],
      ),
    );
  }

  Widget _buildFavoriItem(Favori f) {
    final estActive = _ctrl.titreEnCours == f.nomAnglais;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: estActive
            ? AppColors.primary.withValues(alpha: 0.15)
            : AppColors.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: estActive ? AppColors.primary : AppColors.border,
        ),
      ),
      child: Row(
        children: [
          // Numéro
          Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: estActive ? AppColors.primary : AppColors.surface,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text('${f.numeroSourate}',
                  style: GoogleFonts.syne(
                    color: estActive ? Colors.white : AppColors.textSecondary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  )),
            ),
          ),
          const SizedBox(width: 12),

          // Infos
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(f.nomAnglais,
                    style: GoogleFonts.syne(
                      color: estActive
                          ? AppColors.primary
                          : AppColors.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    )),
                const SizedBox(height: 3),
                Row(
                  children: [
                    Text(f.nomSourate,
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontSize: 14,
                          fontFamily: 'serif',
                        )),
                    const Spacer(),
                    Text(
                      'Ajouté le ${f.ajouteLe.day.toString().padLeft(2, '0')}/'
                      '${f.ajouteLe.month.toString().padLeft(2, '0')}/'
                      '${f.ajouteLe.year}',
                      style: GoogleFonts.syne(
                          color: AppColors.textSecondary, fontSize: 10),
                    ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Bouton play
          GestureDetector(
            onTap: () => estActive
                ? _ctrl.togglePlayPause()
                : _jouer(f),
            child: Icon(
              estActive && _ctrl.player.playing
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
              color: estActive ? AppColors.primary : AppColors.textSecondary,
              size: 32,
            ),
          ),

          const SizedBox(width: 4),

          // Bouton supprimer
          GestureDetector(
            onTap: () => _supprimerAvecEmpreinte(f),
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.delete_outline_rounded,
                  color: AppColors.error, size: 18),
            ),
          ),
        ],
      ),
    );
  }
}


// Fin du fichier — le mini lecteur est géré par GlobalMiniPlayer dans HomeScreen