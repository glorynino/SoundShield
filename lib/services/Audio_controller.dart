// ============================================================
//  lib/services/audio_controller.dart
//  Singleton AudioPlayer partagé entre toutes les pages
//  Accessible depuis n'importe où via AudioController.instance
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sourate_model.dart';

class AudioController extends ChangeNotifier {
  // ── Singleton ─────────────────────────────────────────────────────────────
  static final AudioController instance = AudioController._internal();
  AudioController._internal();

  final AudioPlayer player = AudioPlayer();

  // Sourate en cours (Sourate ou Favori — on garde les infos communes)
  String? _titreEnCours;
  String? _nomArabeEnCours;
  bool _isRepeat = false;

  String? get titreEnCours   => _titreEnCours;
  String? get nomArabeEnCours => _nomArabeEnCours;
  bool get isRepeat           => _isRepeat;
  bool get estEnLecture       => _titreEnCours != null;

  // ── Jouer depuis le lecteur (Sourate) ─────────────────────────────────────
  Future<void> jouerSourate(Sourate s) async {
    if (s.audioUrl == null) return;
    _titreEnCours    = s.nomAnglais;
    _nomArabeEnCours = s.nom;
    notifyListeners();
    await player.setUrl(s.audioUrl!);
    await player.play();
  }

  // ── Jouer depuis les favoris (Favori) ─────────────────────────────────────
  Future<void> jouerFavori(Favori f) async {
    _titreEnCours    = f.nomAnglais;
    _nomArabeEnCours = f.nomSourate;
    notifyListeners();
    await player.setUrl(f.audioUrl);
    await player.play();
  }

  // ── Play / Pause ──────────────────────────────────────────────────────────
  void togglePlayPause() =>
      player.playing ? player.pause() : player.play();

  // ── Répétition ────────────────────────────────────────────────────────────
  void toggleRepeat() {
    _isRepeat = !_isRepeat;
    player.setLoopMode(_isRepeat ? LoopMode.one : LoopMode.off);
    notifyListeners();
  }

  // ── Stop ──────────────────────────────────────────────────────────────────
  void stop() {
    player.stop();
    _titreEnCours    = null;
    _nomArabeEnCours = null;
    notifyListeners();
  }

  // ── Seek ──────────────────────────────────────────────────────────────────
  void seek(double seconds) =>
      player.seek(Duration(seconds: seconds.toInt()));

  void dispose() {
    player.dispose();
    super.dispose();
  }
}