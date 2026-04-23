// ============================================================
//  lib/screens/player_screen.dart
//  Lecteur audio Quran :
//  - Liste catégories (Mecquoises / Médinoises) → sourates
//  - Mini lecteur fixe en bas
//  - Lecture en arrière-plan via just_audio
//  - Lecture / Pause / Répétition
//  - Ajout/suppression favoris (Firestore)
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sourate_model.dart';
import '../services/quran_service.dart';
import '../widgets/app_theme.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _quranService = QuranService();
  final _player       = AudioPlayer();

  List<Sourate> _sourates        = [];
  bool _loadingData              = true;
  String? _erreur;

  Sourate? _sourrenteSourate;
  bool _isPlaying   = false;
  bool _isRepeat    = false;
  bool _isBuffering = false;
  Duration _position  = Duration.zero;
  Duration _duration  = Duration.zero;

  // Catégorie sélectionnée : null = toutes
  String? _categorieSelectionnee;

  // Favoris (ids)
  Set<int> _favorisIds = {};

  @override
  void initState() {
    super.initState();
    _loadSourates();
    _setupPlayerListeners();
    _loadFavorisIds();
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  // ── Chargement ────────────────────────────────────────────────────────────
  Future<void> _loadSourates() async {
    try {
      final sourates = await _quranService.getSourates();
      if (mounted) setState(() { _sourates = sourates; _loadingData = false; });
    } catch (e) {
      if (mounted) setState(() { _erreur = 'Impossible de charger les sourates.'; _loadingData = false; });
    }
  }

  Future<void> _loadFavorisIds() async {
    _quranService.getFavorisStream().listen((favoris) {
      if (mounted) {
        setState(() {
          _favorisIds = favoris.map((f) => f.numeroSourate).toSet();
        });
      }
    });
  }

  // ── Listeners audio ───────────────────────────────────────────────────────
  void _setupPlayerListeners() {
    _player.playingStream.listen((playing) {
      if (mounted) setState(() => _isPlaying = playing);
    });

    _player.positionStream.listen((pos) {
      if (mounted) setState(() => _position = pos);
    });

    _player.durationStream.listen((dur) {
      if (mounted && dur != null) setState(() => _duration = dur);
    });

    _player.processingStateStream.listen((state) {
      if (mounted) {
        setState(() => _isBuffering = state == ProcessingState.buffering ||
            state == ProcessingState.loading);
        // Si terminé + répétition → rejouer
        if (state == ProcessingState.completed && _isRepeat) {
          _player.seek(Duration.zero);
          _player.play();
        }
      }
    });
  }

  // ── Actions lecteur ───────────────────────────────────────────────────────
  Future<void> _jouerSourate(Sourate s) async {
    if (s.audioUrl == null) return;
    try {
      setState(() { _sourrenteSourate = s; _isBuffering = true; });
      await _player.setUrl(s.audioUrl!);
      await _player.play();
    } catch (e) {
      if (mounted) showSnackbar(context, 'Erreur de lecture. Réessayez.');
    }
  }

  void _togglePlayPause() {
    if (_isPlaying) {
      _player.pause();
    } else {
      _player.play();
    }
  }

  void _toggleRepeat() {
    setState(() => _isRepeat = !_isRepeat);
    _player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
  }

  void _seek(double val) {
    final pos = Duration(seconds: val.toInt());
    _player.seek(pos);
  }

  // ── Favoris ───────────────────────────────────────────────────────────────
  Future<void> _toggleFavori(Sourate s) async {
    try {
      if (_favorisIds.contains(s.numero)) {
        await _quranService.supprimerFavori(s.numero);
        if (mounted) showSnackbar(context, '${s.nomAnglais} retiré des favoris.', isError: false);
      } else {
        await _quranService.ajouterFavori(s);
        if (mounted) showSnackbar(context, '${s.nomAnglais} ajouté aux favoris !', isError: false);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, 'Erreur. Réessayez.');
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────
  String _formatDuration(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  List<Sourate> get _souratesFiltrees {
    if (_categorieSelectionnee == null) return _sourates;
    return _sourates.where((s) => s.categorie == _categorieSelectionnee).toList();
  }

  List<String> get _categories {
    return _sourates.map((s) => s.categorie).toSet().toList();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            // ── En-tête ─────────────────────────────────────────────────
            _buildHeader(),

            // ── Filtres catégories ───────────────────────────────────────
            if (!_loadingData && _erreur == null) _buildCategories(),

            // ── Liste sourates ───────────────────────────────────────────
            Expanded(child: _buildBody()),

            // ── Mini lecteur fixe en bas ─────────────────────────────────
            if (_sourrenteSourate != null) _buildMiniPlayer(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('القرآن الكريم',
                  style: GoogleFonts.syne(
                      color: AppColors.accent,
                      fontSize: 13,
                      letterSpacing: 2)),
              Text('Lecteur Audio',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 24,
                      fontWeight: FontWeight.w800)),
            ],
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.border),
            ),
            child: Text('${_sourates.length} sourates',
                style: GoogleFonts.syne(
                    color: AppColors.textSecondary, fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildCategories() {
    final cats = ['Toutes', ..._categories];
    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        itemCount: cats.length,
        separatorBuilder: (_, __) => const SizedBox(width: 8),
        itemBuilder: (_, i) {
          final cat = cats[i];
          final selected = (i == 0 && _categorieSelectionnee == null) ||
              cat == _categorieSelectionnee;
          return GestureDetector(
            onTap: () => setState(() =>
                _categorieSelectionnee = i == 0 ? null : cat),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(cat,
                  style: GoogleFonts.syne(
                    color: selected
                        ? Colors.white
                        : AppColors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  )),
            ),
          );
        },
      ),
    );
  }

  Widget _buildBody() {
    if (_loadingData) {
      return const Center(
          child: CircularProgressIndicator(color: AppColors.primary));
    }
    if (_erreur != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.wifi_off_rounded,
                color: AppColors.textSecondary, size: 48),
            const SizedBox(height: 12),
            Text(_erreur!,
                style: GoogleFonts.syne(color: AppColors.textSecondary)),
            const SizedBox(height: 16),
            TextButton(
              onPressed: () {
                setState(() { _loadingData = true; _erreur = null; });
                _loadSourates();
              },
              child: Text('Réessayer',
                  style: GoogleFonts.syne(color: AppColors.primary)),
            ),
          ],
        ),
      );
    }

    final liste = _souratesFiltrees;
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      itemCount: liste.length,
      itemBuilder: (_, i) => _buildSourateItem(liste[i]),
    );
  }

  Widget _buildSourateItem(Sourate s) {
    final estActive  = _sourrenteSourate?.numero == s.numero;
    final estFavori  = _favorisIds.contains(s.numero);

    return GestureDetector(
      onTap: () => _jouerSourate(s),
      child: Container(
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
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: estActive
                    ? AppColors.primary
                    : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${s.numero}',
                    style: GoogleFonts.syne(
                      color: estActive
                          ? Colors.white
                          : AppColors.textSecondary,
                      fontSize: 12,
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
                  Row(
                    children: [
                      Expanded(
                        child: Text(s.nomAnglais,
                            style: GoogleFonts.syne(
                              color: estActive
                                  ? AppColors.primary
                                  : AppColors.textPrimary,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      Text(s.nom,
                          style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 16,
                            fontFamily: 'serif',
                          )),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Row(
                    children: [
                      Text(s.traduction,
                          style: GoogleFonts.syne(
                              color: AppColors.textSecondary,
                              fontSize: 11)),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: s.type == 'Meccan'
                              ? AppColors.primary.withValues(alpha: 0.15)
                              : AppColors.accent.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(s.categorie,
                            style: GoogleFonts.syne(
                              color: s.type == 'Meccan'
                                  ? AppColors.primaryLight
                                  : AppColors.accent,
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                            )),
                      ),
                      const Spacer(),
                      Text('${s.nbVersets} v.',
                          style: GoogleFonts.syne(
                              color: AppColors.textSecondary,
                              fontSize: 10)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Bouton favori
            GestureDetector(
              onTap: () => _toggleFavori(s),
              child: Icon(
                estFavori ? Icons.favorite_rounded : Icons.favorite_border_rounded,
                color: estFavori ? AppColors.error : AppColors.textSecondary,
                size: 20,
              ),
            ),

            const SizedBox(width: 8),

            // Icône lecture
            if (estActive && _isPlaying)
              const Icon(Icons.equalizer_rounded,
                  color: AppColors.primary, size: 20)
            else
              const Icon(Icons.play_circle_outline_rounded,
                  color: AppColors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }

  // ── Mini lecteur en bas ───────────────────────────────────────────────────
  Widget _buildMiniPlayer() {
    final s = _sourrenteSourate!;
    final maxSec = _duration.inSeconds.toDouble();
    final curSec = _position.inSeconds.toDouble().clamp(0.0, maxSec > 0 ? maxSec : 1.0);

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
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Barre de progression
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              trackHeight: 3,
              thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 5),
              overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
              activeTrackColor: AppColors.primary,
              inactiveTrackColor: AppColors.border,
              thumbColor: AppColors.primary,
              overlayColor: AppColors.primary.withValues(alpha: 0.2),
            ),
            child: Slider(
              value: curSec,
              min: 0,
              max: maxSec > 0 ? maxSec : 1.0,
              onChanged: _seek,
            ),
          ),

          // Temps
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              children: [
                Text(_formatDuration(_position),
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 10)),
                const Spacer(),
                Text(_formatDuration(_duration),
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),

          const SizedBox(height: 8),

          Row(
            children: [
              // Infos sourate
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.nomAnglais,
                        style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis),
                    Text(s.traduction,
                        style: GoogleFonts.syne(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),

              // Bouton répétition
              IconButton(
                onPressed: _toggleRepeat,
                icon: Icon(
                  Icons.repeat_one_rounded,
                  color: _isRepeat ? AppColors.accent : AppColors.textSecondary,
                  size: 22,
                ),
              ),

              // Bouton play/pause
              GestureDetector(
                onTap: _togglePlayPause,
                child: Container(
                  width: 48, height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.primary,
                    shape: BoxShape.circle,
                  ),
                  child: _isBuffering
                      ? const Padding(
                          padding: EdgeInsets.all(14),
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
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

              // Bouton favori
              IconButton(
                onPressed: () => _toggleFavori(s),
                icon: Icon(
                  _favorisIds.contains(s.numero)
                      ? Icons.favorite_rounded
                      : Icons.favorite_border_rounded,
                  color: _favorisIds.contains(s.numero)
                      ? AppColors.error
                      : AppColors.textSecondary,
                  size: 22,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}