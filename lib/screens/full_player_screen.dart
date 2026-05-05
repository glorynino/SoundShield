// ============================================================
//  lib/screens/full_player_screen.dart
//  Lecteur plein écran style Spotify
//  - Ouvert depuis GlobalMiniPlayer (tap)
//  - Artwork avec placeholder animé
//  - Titre, nom arabe, artiste
//  - Favoris, précédent, play/pause, suivant, répétition
//  - Barre de progression avec seek
//  - Fermeture par swipe down ou bouton
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/Audio_controller.dart';
import '../services/quran_service.dart';
import '../models/sourate_model.dart';
import '../widgets/app_theme.dart';

class FullPlayerScreen extends StatefulWidget {
  const FullPlayerScreen({super.key});

  @override
  State<FullPlayerScreen> createState() => _FullPlayerScreenState();
}

class _FullPlayerScreenState extends State<FullPlayerScreen>
    with TickerProviderStateMixin {
  final _ctrl         = AudioController.instance;
  final _quranService = QuranService();

  // Animations
  late AnimationController _artworkController;
  late Animation<double>   _artworkScale;
  late AnimationController _slideController;
  late Animation<Offset>   _slideAnimation;

  bool _isPlaying   = false;
  bool _isBuffering = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  bool _isFavori    = false;

  @override
  void initState() {
    super.initState();

    // Animation artwork (pulse quand lecture)
    _artworkController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _artworkScale = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _artworkController, curve: Curves.easeOutBack),
    );

    // Animation slide entrée
    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(
        parent: _slideController, curve: Curves.easeOutCubic));

    _slideController.forward();

    // Écouter le player
    _ctrl.player.playingStream.listen((v) {
      if (mounted) {
        setState(() => _isPlaying = v);
        if (v) {
          _artworkController.forward();
        } else {
          _artworkController.reverse();
        }
      }
    });

    _ctrl.player.positionStream.listen(
        (v) { if (mounted) setState(() => _position = v); });

    _ctrl.player.durationStream.listen(
        (v) { if (mounted && v != null) setState(() => _duration = v); });

    _ctrl.player.processingStateStream.listen((s) {
      if (mounted) {
        setState(() => _isBuffering =
            s == ProcessingState.buffering || s == ProcessingState.loading);
      }
    });

    _ctrl.addListener(_onControllerChange);

    // État initial
    _isPlaying = _ctrl.player.playing;
    if (_isPlaying) _artworkController.forward();

    // Vérifier si favori
    _checkFavori();
  }

  @override
  void dispose() {
    _artworkController.dispose();
    _slideController.dispose();
    _ctrl.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) {
      setState(() {});
      _checkFavori();
    }
  }

  Future<void> _checkFavori() async {
    if (_ctrl.numeroSourateEnCours == null) return;
    final estFavori =
        await _quranService.estFavori(_ctrl.numeroSourateEnCours!);
    if (mounted) setState(() => _isFavori = estFavori);
  }

  Future<void> _toggleFavori() async {
    if (_ctrl.numeroSourateEnCours == null || _ctrl.titreEnCours == null ||
        _ctrl.nomArabeEnCours == null || _ctrl.audioUrlEnCours == null) return;

    if (_isFavori) {
      await _quranService.supprimerFavori(_ctrl.numeroSourateEnCours!);
      if (mounted) setState(() => _isFavori = false);
    } else {
      final s = Sourate(
        numero:     _ctrl.numeroSourateEnCours!,
        nom:        _ctrl.nomArabeEnCours!,
        nomAnglais: _ctrl.titreEnCours!,
        traduction: _ctrl.traductionEnCours ?? '',
        type:       '',
        nbVersets:  0,
        audioUrl:   _ctrl.audioUrlEnCours,
      );
      await _quranService.ajouterFavori(s);
      if (mounted) setState(() => _isFavori = true);
    }
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  Future<void> _fermer() async {
    await _slideController.reverse();
    if (mounted) Navigator.pop(context);
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final maxSec = _duration.inSeconds.toDouble();
    final curSec = _position.inSeconds
        .toDouble()
        .clamp(0.0, maxSec > 0 ? maxSec : 1.0);
    final pct = maxSec > 0 ? curSec / maxSec : 0.0;

    return SlideTransition(
      position: _slideAnimation,
      child: GestureDetector(
        onVerticalDragEnd: (d) {
          if (d.primaryVelocity != null && d.primaryVelocity! > 300) {
            _fermer();
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.background,
          body: Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color(0xFF1A1040),
                  AppColors.background,
                ],
                stops: [0.0, 0.5],
              ),
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 28),
                child: Column(
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const SizedBox(height: 32),
                    _buildArtwork(),
                    const SizedBox(height: 36),
                    _buildSourateInfo(),
                    const SizedBox(height: 28),
                    _buildProgressBar(curSec, maxSec, pct),
                    const SizedBox(height: 28),
                    _buildControls(),
                    const SizedBox(height: 24),
                    _buildExtras(),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Barre du haut ─────────────────────────────────────────────────────────
  Widget _buildTopBar() {
    return Row(
      children: [
        GestureDetector(
          onTap: _fermer,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.keyboard_arrow_down_rounded,
                color: Colors.white, size: 28),
          ),
        ),
        const Spacer(),
        Text('En lecture',
            style: GoogleFonts.syne(
                color: AppColors.textSecondary,
                fontSize: 13,
                letterSpacing: 1)),
        const Spacer(),
        GestureDetector(
          onTap: _toggleFavori,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              _isFavori
                  ? Icons.favorite_rounded
                  : Icons.favorite_border_rounded,
              color: _isFavori ? AppColors.error : Colors.white,
              size: 20,
            ),
          ),
        ),
      ],
    );
  }

  // ── Artwork ───────────────────────────────────────────────────────────────
  Widget _buildArtwork() {
    return ScaleTransition(
      scale: _artworkScale,
      child: Container(
        width: double.infinity,
        height: 280,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.8),
              AppColors.accent.withValues(alpha: 0.6),
              const Color(0xFF1A1040),
            ],
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Cercles décoratifs
            Positioned(
              top: -30, right: -30,
              child: Container(
                width: 160, height: 160,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.05),
                ),
              ),
            ),
            Positioned(
              bottom: -20, left: -20,
              child: Container(
                width: 120, height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.accent.withValues(alpha: 0.1),
                ),
              ),
            ),
            // Nom arabe au centre
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (_isBuffering)
                  const CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2)
                else ...[
                  Text(
                    _ctrl.nomArabeEnCours ?? '﷽',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 52,
                      fontFamily: 'serif',
                      height: 1.4,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: Colors.white.withValues(alpha: 0.2)),
                    ),
                    child: Text(
                      'Mishary Rashid Alafasy',
                      style: GoogleFonts.syne(
                          color: Colors.white70, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Infos sourate ─────────────────────────────────────────────────────────
  Widget _buildSourateInfo() {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                _ctrl.titreEnCours ?? 'Chargement...',
                style: GoogleFonts.syne(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              Text(
                _ctrl.traductionEnCours ?? '',
                style: GoogleFonts.syne(
                    color: AppColors.textSecondary, fontSize: 14),
              ),
            ],
          ),
        ),
        const SizedBox(width: 16),
        // Numéro de sourate
        Container(
          width: 48, height: 48,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.4)),
          ),
          child: Center(
            child: Text(
              '${_ctrl.numeroSourateEnCours ?? ""}',
              style: GoogleFonts.syne(
                  color: AppColors.primary,
                  fontSize: 16,
                  fontWeight: FontWeight.w800),
            ),
          ),
        ),
      ],
    );
  }

  // ── Barre de progression ──────────────────────────────────────────────────
  Widget _buildProgressBar(double curSec, double maxSec, double pct) {
    return Column(
      children: [
        // Barre custom
        GestureDetector(
          onHorizontalDragUpdate: (d) {
            final box = context.findRenderObject() as RenderBox;
            final localX = d.localPosition.dx;
            final width  = box.size.width - 56; // padding 28*2
            final ratio  = (localX / width).clamp(0.0, 1.0);
            _ctrl.seek(ratio * maxSec);
          },
          child: Container(
            height: 5,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(3),
            ),
            child: FractionallySizedBox(
              alignment: Alignment.centerLeft,
              widthFactor: pct.clamp(0.0, 1.0),
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, AppColors.accent]),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Text(_fmt(_position),
                style: GoogleFonts.syne(
                    color: AppColors.textSecondary, fontSize: 11)),
            const Spacer(),
            Text(_fmt(_duration),
                style: GoogleFonts.syne(
                    color: AppColors.textSecondary, fontSize: 11)),
          ],
        ),
      ],
    );
  }

  // ── Contrôles principaux ──────────────────────────────────────────────────
  Widget _buildControls() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        // Précédent
        GestureDetector(
          onTap: _ctrl.precedent,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.skip_previous_rounded,
                color: Colors.white, size: 28),
          ),
        ),

        // Play / Pause principal
        GestureDetector(
          onTap: _ctrl.togglePlayPause,
          child: Container(
            width: 72, height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [AppColors.primary, AppColors.accent],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.5),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: _isBuffering
                ? const Padding(
                    padding: EdgeInsets.all(20),
                    child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation(Colors.white)),
                  )
                : Icon(
                    _isPlaying
                        ? Icons.pause_rounded
                        : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
          ),
        ),

        // Suivant
        GestureDetector(
          onTap: _ctrl.suivant,
          child: Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.skip_next_rounded,
                color: Colors.white, size: 28),
          ),
        ),
      ],
    );
  }

  // ── Extras : répétition ───────────────────────────────────────────────────
  Widget _buildExtras() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        GestureDetector(
          onTap: _ctrl.toggleRepeat,
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: _ctrl.isRepeat
                  ? AppColors.accent.withValues(alpha: 0.15)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: _ctrl.isRepeat
                    ? AppColors.accent.withValues(alpha: 0.4)
                    : Colors.transparent,
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.repeat_one_rounded,
                    color: _ctrl.isRepeat
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 18),
                const SizedBox(width: 6),
                Text('Répéter',
                    style: GoogleFonts.syne(
                      color: _ctrl.isRepeat
                          ? AppColors.accent
                          : AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    )),
              ],
            ),
          ),
        ),
      ],
    );
  }
}