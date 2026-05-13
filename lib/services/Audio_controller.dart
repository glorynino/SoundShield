// ============================================================
//  lib/services/audio_controller.dart
//  Singleton AudioPlayer — partagé entre toutes les pages
//  Ajout : numéro sourate, traduction, audioUrl, prev/next
// ============================================================

import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import '../models/sourate_model.dart';

class AudioController extends ChangeNotifier {
  static final AudioController instance = AudioController._internal();
  AudioController._internal();

  final AudioPlayer player = AudioPlayer();

  // ── Infos de la sourate en cours ─────────────────────────────────────────
  String? _titreEnCours;
  String? _nomArabeEnCours;
  String? _traductionEnCours;
  String? _audioUrlEnCours;
  int?    _numeroSourateEnCours;
  bool    _isRepeat = false;

  // Playlist complète (pour précédent/suivant)
  List<Sourate> _playlist = [];

  // ── Getters ───────────────────────────────────────────────────────────────
  String? get titreEnCours          => _titreEnCours;
  String? get nomArabeEnCours       => _nomArabeEnCours;
  String? get traductionEnCours     => _traductionEnCours;
  String? get audioUrlEnCours       => _audioUrlEnCours;
  int?    get numeroSourateEnCours  => _numeroSourateEnCours;
  bool    get isRepeat              => _isRepeat;
  bool    get estEnLecture          => _titreEnCours != null;

  // ── Définir la playlist (appelé depuis PlayerScreen après chargement) ─────
  void setPlaylist(List<Sourate> sourates) {
    _playlist = sourates;
  }

  // ── Jouer une Sourate ─────────────────────────────────────────────────────
  Future<void> jouerSourate(Sourate s) async {
    if (s.audioUrl == null) return;
    _setInfos(
      titre:       s.nomAnglais,
      nomArabe:    s.nom,
      traduction:  s.traduction,
      audioUrl:    s.audioUrl!,
      numero:      s.numero,
    );
    await player.setUrl(s.audioUrl!);
    await player.play();
  }

  // ── Jouer un Favori ───────────────────────────────────────────────────────
  Future<void> jouerFavori(Favori f) async {
    _setInfos(
      titre:      f.nomAnglais,
      nomArabe:   f.nomSourate,
      traduction: '',
      audioUrl:   f.audioUrl,
      numero:     f.numeroSourate,
    );
    await player.setUrl(f.audioUrl);
    await player.play();
  }

  void _setInfos({
    required String titre,
    required String nomArabe,
    required String traduction,
    required String audioUrl,
    required int    numero,
  }) {
    _titreEnCours         = titre;
    _nomArabeEnCours      = nomArabe;
    _traductionEnCours    = traduction;
    _audioUrlEnCours      = audioUrl;
    _numeroSourateEnCours = numero;
    notifyListeners();
  }

  // ── Précédent ─────────────────────────────────────────────────────────────
  Future<void> precedent() async {
    if (_playlist.isEmpty || _numeroSourateEnCours == null) return;
    final idx = _playlist.indexWhere((s) => s.numero == _numeroSourateEnCours);
    if (idx <= 0) return;
    await jouerSourate(_playlist[idx - 1]);
  }

  // ── Suivant ───────────────────────────────────────────────────────────────
  Future<void> suivant() async {
    if (_playlist.isEmpty || _numeroSourateEnCours == null) return;
    final idx = _playlist.indexWhere((s) => s.numero == _numeroSourateEnCours);
    if (idx < 0 || idx >= _playlist.length - 1) return;
    await jouerSourate(_playlist[idx + 1]);
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
    _titreEnCours         = null;
    _nomArabeEnCours      = null;
    _traductionEnCours    = null;
    _audioUrlEnCours      = null;
    _numeroSourateEnCours = null;
    notifyListeners();
  }

  // ── Seek ──────────────────────────────────────────────────────────────────
  void seek(double seconds) =>
      player.seek(Duration(seconds: seconds.toInt()));

  @override
  void dispose() {
    player.dispose();
    super.dispose();
  }
}