// ============================================================
//  lib/screens/favorites_screen.dart
//  Fix : StreamBuilder Firestore isolé du lecteur audio
//  → plus de rechargement en boucle pendant la lecture
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sourate_model.dart';
import '../services/quran_service.dart';
import '../services/biometric_service.dart';
import '../widgets/app_theme.dart';

// ── Lecteur audio partagé (singleton) ────────────────────────────────────────
// Un seul AudioPlayer pour toute la page → pas recréé à chaque rebuild
final _sharedPlayer = AudioPlayer();

class FavoritesScreen extends StatefulWidget {
  const FavoritesScreen({super.key});

  @override
  State<FavoritesScreen> createState() => _FavoritesScreenState();
}

class _FavoritesScreenState extends State<FavoritesScreen> {
  final _quranService     = QuranService();
  final _biometricService = BiometricService();

  // On garde seulement _enLecture ici (pas les streams du player)
  // pour savoir quelle sourate est active dans la liste
  Favori? _enLecture;

  @override
  void dispose() {
    _sharedPlayer.stop();
    super.dispose();
  }

  // ── Lecture ───────────────────────────────────────────────────────────────
  Future<void> _jouer(Favori f) async {
    try {
      // setState minimal : juste mettre à jour quelle sourate est active
      setState(() => _enLecture = f);
      await _sharedPlayer.setUrl(f.audioUrl);
      await _sharedPlayer.play();
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
    if (_enLecture?.numeroSourate == f.numeroSourate) {
      await _sharedPlayer.stop();
      if (mounted) setState(() => _enLecture = null);
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

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header (statique, jamais rebuild) ───────────────────────
            _buildHeader(),

            // ── Liste Firestore (isolée du lecteur) ──────────────────────
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
                    itemBuilder: (_, i) =>
                        _buildFavoriItem(favoris[i]),
                  );
                },
              ),
            ),

            // ── Mini lecteur (widget séparé avec ses propres streams) ────
            // Il se rebuild tout seul sans toucher à la liste Firestore
            if (_enLecture != null)
              _MiniPlayer(
                favori: _enLecture!,
                player: _sharedPlayer,
                onSupprimer: () => _supprimerAvecEmpreinte(_enLecture!),
              ),
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
    final estActive = _enLecture?.numeroSourate == f.numeroSourate;

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
                ? (_sharedPlayer.playing
                    ? _sharedPlayer.pause()
                    : _sharedPlayer.play())
                : _jouer(f),
            child: Icon(
              estActive && _sharedPlayer.playing
                  ? Icons.pause_circle_rounded
                  : Icons.play_circle_rounded,
              color:
                  estActive ? AppColors.primary : AppColors.textSecondary,
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

// ============================================================
//  Widget mini lecteur SÉPARÉ
//  Gère ses propres streams → ne déclenche JAMAIS de rebuild
//  dans FavoritesScreen ou dans le StreamBuilder Firestore
// ============================================================
class _MiniPlayer extends StatefulWidget {
  final Favori favori;
  final AudioPlayer player;
  final VoidCallback onSupprimer;

  const _MiniPlayer({
    required this.favori,
    required this.player,
    required this.onSupprimer,
  });

  @override
  State<_MiniPlayer> createState() => _MiniPlayerState();
}

class _MiniPlayerState extends State<_MiniPlayer> {
  bool _isPlaying   = false;
  bool _isBuffering = false;
  bool _isRepeat    = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;

  @override
  void initState() {
    super.initState();
    // Les streams du player sont écoutés ICI uniquement
    // → setState ne remonte jamais vers FavoritesScreen
    widget.player.playingStream.listen(
        (v) { if (mounted) setState(() => _isPlaying = v); });
    widget.player.positionStream.listen(
        (v) { if (mounted) setState(() => _position = v); });
    widget.player.durationStream.listen(
        (v) { if (mounted && v != null) setState(() => _duration = v); });
    widget.player.processingStateStream.listen((s) {
      if (!mounted) return;
      setState(() => _isBuffering =
          s == ProcessingState.buffering || s == ProcessingState.loading);
      if (s == ProcessingState.completed && _isRepeat) {
        widget.player.seek(Duration.zero);
        widget.player.play();
      }
    });
  }

  void _toggleRepeat() {
    setState(() => _isRepeat = !_isRepeat);
    widget.player.setLoopMode(
        _isRepeat ? LoopMode.one : LoopMode.off);
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    final maxSec = _duration.inSeconds.toDouble();
    final curSec = _position.inSeconds
        .toDouble()
        .clamp(0.0, maxSec > 0 ? maxSec : 1.0);

    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de progression
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape:
                  const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape:
                  const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: curSec,
              min: 0,
              max: maxSec > 0 ? maxSec : 1.0,
              onChanged: (v) =>
                  widget.player.seek(Duration(seconds: v.toInt())),
            ),
          ),

          // Temps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(_fmt(_position),
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 10)),
                const Spacer(),
                Text(_fmt(_duration),
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),

          const SizedBox(height: 6),

          Row(
            children: [
              // Infos sourate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.favori.nomAnglais,
                        style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(widget.favori.nomSourate,
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontFamily: 'serif')),
                  ],
                ),
              ),

              // Répétition
              IconButton(
                onPressed: _toggleRepeat,
                icon: Icon(Icons.repeat_one_rounded,
                    color: _isRepeat
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 22),
              ),

              // Play/Pause
              GestureDetector(
                onTap: () => _isPlaying
                    ? widget.player.pause()
                    : widget.player.play(),
                child: Container(
                  width: 48, height: 48,
                  decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle),
                  child: _isBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor:
                                AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Icon(
                          _isPlaying
                              ? Icons.pause_rounded
                              : Icons.play_arrow_rounded,
                          color: Colors.white,
                          size: 26,
                        ),
                ),
              ),

              // Supprimer
              IconButton(
                onPressed: widget.onSupprimer,
                icon: const Icon(Icons.delete_outline_rounded,
                    color: AppColors.error, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}