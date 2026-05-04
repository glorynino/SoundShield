// ============================================================
//  lib/widgets/global_mini_player.dart
//  Mini lecteur affiché en permanence dans HomeScreen
//  au-dessus de la BottomNavigationBar
//  Visible sur les 3 onglets pendant la lecture
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/audio_controller.dart';
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
      if (!mounted) return;
      setState(() => _isBuffering =
          s == ProcessingState.buffering || s == ProcessingState.loading);
      if (s == ProcessingState.completed && _ctrl.isRepeat) {
        _ctrl.player.seek(Duration.zero);
        _ctrl.player.play();
      }
    });

    // Écouter les changements de sourate (titre, etc.)
    _ctrl.addListener(() { if (mounted) setState(() {}); });
  }

  String _fmt(Duration d) {
    final m = d.inMinutes.remainder(60).toString().padLeft(2, '0');
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    // Caché si rien n'est en lecture
    if (!_ctrl.estEnLecture) return const SizedBox.shrink();

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
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Barre de progression ──────────────────────────────────────
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
              onChanged: _ctrl.seek,
            ),
          ),

          // ── Temps ─────────────────────────────────────────────────────
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

          const SizedBox(height: 4),

          // ── Contrôles ─────────────────────────────────────────────────
          Row(
            children: [
              // Titre + nom arabe
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
                    Text(_ctrl.nomArabeEnCours ?? '',
                        style: const TextStyle(
                            color: AppColors.accent,
                            fontSize: 13,
                            fontFamily: 'serif')),
                  ],
                ),
              ),

              // Répétition
              IconButton(
                onPressed: _ctrl.toggleRepeat,
                icon: Icon(Icons.repeat_one_rounded,
                    color: _ctrl.isRepeat
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    size: 22),
              ),

              // Play / Pause
              GestureDetector(
                onTap: _ctrl.togglePlayPause,
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
                          size: 26),
                ),
              ),

              // Stop
              IconButton(
                onPressed: _ctrl.stop,
                icon: const Icon(Icons.stop_rounded,
                    color: AppColors.textSecondary, size: 22),
              ),
            ],
          ),
        ],
      ),
    );
  }
}