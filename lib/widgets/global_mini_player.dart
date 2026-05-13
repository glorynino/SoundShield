// ============================================================
//  lib/widgets/global_mini_player.dart
//  Mini lecteur — tap → ouvre FullPlayerScreen
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/Audio_controller.dart';
import '../screens/full_player_screen.dart';
import 'app_theme.dart';

class GlobalMiniPlayer extends StatefulWidget {
  const GlobalMiniPlayer({super.key});

  @override
  State<GlobalMiniPlayer> createState() => _GlobalMiniPlayerState();
}

class _GlobalMiniPlayerState extends State<GlobalMiniPlayer> {
  final _ctrl = AudioController.instance;

  bool     _isPlaying   = false;
  bool     _isBuffering = false;
  Duration _position    = Duration.zero;
  Duration _duration    = Duration.zero;

  @override
  void initState() {
    super.initState();

    _ctrl.player.playingStream.listen(
        (v) { if (mounted) setState(() => _isPlaying = v); });
    _ctrl.player.positionStream.listen(
        (v) { if (mounted) setState(() => _position = v); });
    _ctrl.player.durationStream.listen(
        (v) { if (mounted && v != null) setState(() => _duration = v); });
    _ctrl.player.processingStateStream.listen((s) {
      if (mounted) {
        setState(() => _isBuffering =
            s == ProcessingState.buffering || s == ProcessingState.loading);
        if (s == ProcessingState.completed && _ctrl.isRepeat) {
          _ctrl.player.seek(Duration.zero);
          _ctrl.player.play();
        }
      }
    });

    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  void _ouvrirFullPlayer() {
    Navigator.of(context).push(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const FullPlayerScreen(),
        transitionDuration: const Duration(milliseconds: 400),
        transitionsBuilder: (_, animation, __, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 1),
              end: Offset.zero,
            ).animate(CurvedAnimation(
                parent: animation, curve: Curves.easeOutCubic)),
            child: child,
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (!_ctrl.estEnLecture) return const SizedBox.shrink();

    final maxSec = _duration.inSeconds.toDouble();
    final curSec = _position.inSeconds
        .toDouble()
        .clamp(0.0, maxSec > 0 ? maxSec : 1.0);
    final pct = maxSec > 0 ? curSec / maxSec : 0.0;

    return GestureDetector(
      // Tap n'importe où sur le mini lecteur → ouvre le plein écran
      onTap: _ouvrirFullPlayer,
      child: Container(
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
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Barre de progression fine en haut ─────────────────────────
            Container(
              height: 3,
              child: FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: pct.clamp(0.0, 1.0),
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                        colors: [AppColors.primary, AppColors.accent]),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 8, 12),
              child: Row(
                children: [
                  // ── Artwork miniature ────────────────────────────────────
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      gradient: LinearGradient(
                        colors: [
                          AppColors.primary.withValues(alpha: 0.8),
                          AppColors.accent.withValues(alpha: 0.6),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        _ctrl.nomArabeEnCours?.isNotEmpty == true
                            ? _ctrl.nomArabeEnCours![0]
                            : '﷽',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontFamily: 'serif'),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  // ── Titre + artiste ──────────────────────────────────────
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(_ctrl.titreEnCours ?? '',
                            style: GoogleFonts.syne(
                              color: AppColors.textPrimary,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        Text('Mishary Rashid Alafasy',
                            style: GoogleFonts.syne(
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),

                  // ── Précédent ────────────────────────────────────────────
                  IconButton(
                    onPressed: _ctrl.precedent,
                    icon: const Icon(Icons.skip_previous_rounded,
                        color: AppColors.textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),

                  // ── Play / Pause ─────────────────────────────────────────
                  IconButton(
                    onPressed: _ctrl.togglePlayPause,
                    icon: _isBuffering
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor:
                                  AlwaysStoppedAnimation(Colors.white),
                            ))
                        : Icon(
                            _isPlaying
                                ? Icons.pause_rounded
                                : Icons.play_arrow_rounded,
                            color: Colors.white,
                            size: 28),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 40, minHeight: 40),
                  ),

                  // ── Suivant ──────────────────────────────────────────────
                  IconButton(
                    onPressed: _ctrl.suivant,
                    icon: const Icon(Icons.skip_next_rounded,
                        color: AppColors.textSecondary, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(
                        minWidth: 36, minHeight: 36),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}