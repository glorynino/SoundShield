// ============================================================
//  lib/services/quran_service.dart
//  - Récupère les sourates via api.alquran.cloud
//  - Récupère les URLs audio via api.quran.com
//  - Gère les favoris dans Firestore
// ============================================================

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sourate_model.dart';

class QuranService {
  static const _surahsUrl =
      'https://api.alquran.cloud/v1/surah';

  // Récitateur par défaut : Mishary Rashid Alafasy (id=7 sur quran.com)
  static const _reciterId = 7;
  static const _audioBase =
      'https://download.quranicaudio.com/quran/mishaari_raashid_al_3afaasee/';

  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Récupérer toutes les sourates avec leurs URLs audio ──────────────────
  Future<List<Sourate>> getSourates() async {
    final response = await http.get(Uri.parse(_surahsUrl));
    if (response.statusCode != 200) {
      throw Exception('Erreur chargement sourates');
    }

    final data = jsonDecode(response.body);
    final List items = data['data'];

    return items.map((json) {
      final num = (json['number'] as int).toString().padLeft(3, '0');
      final audioUrl = '$_audioBase$num.mp3';
      return Sourate.fromJson(json, audioUrl: audioUrl);
    }).toList();
  }

  // ── Favoris : ajouter ────────────────────────────────────────────────────
  Future<void> ajouterFavori(Sourate s) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final favori = Favori(
      uid:           uid,
      numeroSourate: s.numero,
      nomSourate:    s.nom,
      nomAnglais:    s.nomAnglais,
      audioUrl:      s.audioUrl ?? '',
      ajouteLe:      DateTime.now(),
    );

    await _db
        .collection('users')
        .doc(uid)
        .collection('favoris')
        .doc('sourate_${s.numero}')
        .set(favori.toFirestore());
  }

  // ── Favoris : supprimer (nécessite empreinte côté UI) ────────────────────
  Future<void> supprimerFavori(int numeroSourate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    await _db
        .collection('users')
        .doc(uid)
        .collection('favoris')
        .doc('sourate_$numeroSourate')
        .delete();
  }

  // ── Favoris : stream temps réel ──────────────────────────────────────────
  Stream<List<Favori>> getFavorisStream() {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return const Stream.empty();

    return _db
        .collection('users')
        .doc(uid)
        .collection('favoris')
        .orderBy('ajouteLe', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Favori.fromFirestore(d.data()))
            .toList());
  }

  // ── Vérifier si une sourate est en favori ────────────────────────────────
  Future<bool> estFavori(int numeroSourate) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return false;

    final doc = await _db
        .collection('users')
        .doc(uid)
        .collection('favoris')
        .doc('sourate_$numeroSourate')
        .get();
    return doc.exists;
  }
}