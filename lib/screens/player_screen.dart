// ============================================================
//  lib/screens/player_screen.dart
//  Fusion : AudioController global + tracking stats Firestore
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/sourate_model.dart';
import '../services/quran_service.dart';
import '../services/stats_service.dart';
import '../services/audio_controller.dart';
import '../widgets/app_theme.dart';
import 'package:just_audio/just_audio.dart';

class PlayerScreen extends StatefulWidget {
  const PlayerScreen({super.key});

  @override
  State<PlayerScreen> createState() => _PlayerScreenState();
}

class _PlayerScreenState extends State<PlayerScreen> {
  final _quranService = QuranService();
  final _statsService = StatsService();
  final _ctrl         = AudioController.instance;

  List<Sourate> _sourates        = [];
  bool _loadingData              = true;
  String? _erreur;
  String? _categorieSelectionnee;
  Set<int> _favorisIds           = {};

  // ── Timer stats ───────────────────────────────────────────────────────────
  Timer? _minuteTimer;
  int    _secondesEcoute = 0;
  int?   _dernierNumeroSourate;

  @override
  void initState() {
    super.initState();
    _loadSourates();
    _loadFavorisIds();
    _ctrl.addListener(_onControllerChange);

    // Écouter le stream playing pour démarrer/arrêter le timer stats
    _ctrl.player.playingStream.listen((playing) {
      if (playing) {
        _startMinuteTimer();
      } else {
        _stopMinuteTimer();
      }
    });

    // Détecter changement de sourate pour enregistrer le début d'écoute
    _ctrl.player.processingStateStream.listen((state) {
      if (state == ProcessingState.completed && !_ctrl.isRepeat) {
        _stopMinuteTimer();
      }
    });
  }

  @override
  void dispose() {
    _stopMinuteTimer();
    _ctrl.removeListener(_onControllerChange);
    super.dispose();
  }

  void _onControllerChange() {
    if (mounted) setState(() {});
  }

  // ── Timer : 1 tick/seconde → toutes les 60s on enregistre 1 minute ───────
  void _startMinuteTimer() {
    _minuteTimer?.cancel();
    _minuteTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_ctrl.titreEnCours == null) return;
      _secondesEcoute++;
      if (_secondesEcoute >= 60) {
        _secondesEcoute = 0;
        // Trouver la sourate active dans la liste
        final s = _sourates.firstWhere(
          (s) => s.nomAnglais == _ctrl.titreEnCours,
          orElse: () => _sourates.first,
        );
        _statsService.enregistrerMinute(
          numeroSourate: s.numero,
          nomSourate:    s.nomAnglais,
        );
      }
    });
  }

  void _stopMinuteTimer() {
    _minuteTimer?.cancel();
    _minuteTimer = null;
  }

  // ── Chargement données ────────────────────────────────────────────────────
  Future<void> _loadSourates() async {
    try {
      final s = await _quranService.getSourates();
      if (mounted) setState(() { _sourates = s; _loadingData = false; });
    } catch (e) {
      if (mounted) setState(() {
        _erreur      = 'Impossible de charger les sourates.';
        _loadingData = false;
      });
    }
  }

  Future<void> _loadFavorisIds() async {
    _quranService.getFavorisStream().listen((favoris) {
      if (mounted) setState(() {
        _favorisIds = favoris.map((f) => f.numeroSourate).toSet();
      });
    });
  }

  // ── Jouer une sourate ─────────────────────────────────────────────────────
  Future<void> _jouerSourate(Sourate s) async {
    // Si c'est une nouvelle sourate → enregistrer début d'écoute
    if (_dernierNumeroSourate != s.numero) {
      _secondesEcoute = 0;
      _dernierNumeroSourate = s.numero;
      await _statsService.enregistrerDebutEcoute(
        numeroSourate: s.numero,
        nomSourate:    s.nomAnglais,
      );
    }
    await _ctrl.jouerSourate(s);
  }

  // ── Favoris ───────────────────────────────────────────────────────────────
  Future<void> _toggleFavori(Sourate s) async {
    try {
      if (_favorisIds.contains(s.numero)) {
        await _quranService.supprimerFavori(s.numero);
        if (mounted) showSnackbar(context,
            '${s.nomAnglais} retiré des favoris.', isError: false);
      } else {
        await _quranService.ajouterFavori(s);
        if (mounted) showSnackbar(context,
            '${s.nomAnglais} ajouté aux favoris !', isError: false);
      }
    } catch (e) {
      if (mounted) showSnackbar(context, 'Erreur. Réessayez.');
    }
  }

  List<Sourate> get _souratesFiltrees {
    if (_categorieSelectionnee == null) return _sourates;
    return _sourates
        .where((s) => s.categorie == _categorieSelectionnee)
        .toList();
  }

  List<String> get _categories =>
      _sourates.map((s) => s.categorie).toSet().toList();

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            _buildHeader(),
            if (!_loadingData && _erreur == null) _buildCategories(),
            Expanded(child: _buildBody()),
            // Mini lecteur géré par GlobalMiniPlayer dans HomeScreen
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
          final cat      = cats[i];
          final selected = (i == 0 && _categorieSelectionnee == null) ||
              cat == _categorieSelectionnee;
          return GestureDetector(
            onTap: () => setState(() =>
                _categorieSelectionnee = i == 0 ? null : cat),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: selected ? AppColors.primary : AppColors.card,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                    color: selected ? AppColors.primary : AppColors.border),
              ),
              child: Text(cat,
                  style: GoogleFonts.syne(
                    color: selected ? Colors.white : AppColors.textSecondary,
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

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 8),
      itemCount: _souratesFiltrees.length,
      itemBuilder: (_, i) => _buildSourateItem(_souratesFiltrees[i]),
    );
  }

  Widget _buildSourateItem(Sourate s) {
    final estActive = _ctrl.titreEnCours == s.nomAnglais;
    final estFavori = _favorisIds.contains(s.numero);

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
              color: estActive ? AppColors.primary : AppColors.border),
        ),
        child: Row(
          children: [
            // Numéro
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: estActive ? AppColors.primary : AppColors.surface,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${s.numero}',
                    style: GoogleFonts.syne(
                      color: estActive ? Colors.white : AppColors.textSecondary,
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
                  Row(children: [
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
                  ]),
                  const SizedBox(height: 3),
                  Row(children: [
                    Text(s.traduction,
                        style: GoogleFonts.syne(
                            color: AppColors.textSecondary, fontSize: 11)),
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
                            color: AppColors.textSecondary, fontSize: 10)),
                  ]),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Favori
            GestureDetector(
              onTap: () => _toggleFavori(s),
              child: Icon(
                estFavori
                    ? Icons.favorite_rounded
                    : Icons.favorite_border_rounded,
                color: estFavori ? AppColors.error : AppColors.textSecondary,
                size: 20,
              ),
            ),

            const SizedBox(width: 8),

            // État lecture
            if (estActive && _ctrl.player.playing)
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
}