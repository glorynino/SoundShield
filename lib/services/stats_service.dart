// ============================================================
//  lib/services/stats_service.dart
//  Enregistre et lit les statistiques d'écoute dans Firestore
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsService {
  final _db   = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ── Enregistrer 1 minute d'écoute ────────────────────────────────────────
  Future<void> enregistrerMinute({
    required int numeroSourate,
    required String nomSourate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now     = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(dateKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);

      if (!snap.exists) {
        tx.set(docRef, {
          'date': dateKey,
          'minutesTotal': 1,
          'sourates': {
            '$numeroSourate': {
              'nom': nomSourate,
              'minutes': 1,
              'ecoutes': 1,
            }
          }
        });
      } else {
        final data        = snap.data()!;
        final souratesMap = Map<String, dynamic>.from(data['sourates'] ?? {});
        final key         = '$numeroSourate';

        if (souratesMap.containsKey(key)) {
          souratesMap[key] = {
            'nom':     nomSourate,
            'minutes': (souratesMap[key]['minutes'] ?? 0) + 1,
            'ecoutes': souratesMap[key]['ecoutes'] ?? 1,
          };
        } else {
          souratesMap[key] = {
            'nom':     nomSourate,
            'minutes': 1,
            'ecoutes': 1,
          };
        }

        tx.update(docRef, {
          'minutesTotal': (data['minutesTotal'] ?? 0) + 1,
          'sourates': souratesMap,
        });
      }
    });
  }

  // ── Enregistrer le début d'une nouvelle écoute ───────────────────────────
  Future<void> enregistrerDebutEcoute({
    required int numeroSourate,
    required String nomSourate,
  }) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;

    final now     = DateTime.now();
    final dateKey = '${now.year}-${now.month.toString().padLeft(2,'0')}-${now.day.toString().padLeft(2,'0')}';

    final docRef = _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(dateKey);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(docRef);
      final key  = '$numeroSourate';

      if (!snap.exists) {
        tx.set(docRef, {
          'date': dateKey,
          'minutesTotal': 0,
          'sourates': {
            key: {'nom': nomSourate, 'minutes': 0, 'ecoutes': 1}
          }
        });
      } else {
        final data        = snap.data()!;
        final souratesMap = Map<String, dynamic>.from(data['sourates'] ?? {});

        if (souratesMap.containsKey(key)) {
          souratesMap[key] = {
            'nom':     nomSourate,
            'minutes': souratesMap[key]['minutes'] ?? 0,
            'ecoutes': (souratesMap[key]['ecoutes'] ?? 0) + 1,
          };
        } else {
          souratesMap[key] = {'nom': nomSourate, 'minutes': 0, 'ecoutes': 1};
        }

        tx.update(docRef, {'sourates': souratesMap});
      }
    });
  }

  // ── Minutes par jour du mois courant ─────────────────────────────────────
  Future<Map<int, int>> getMinutesParJourMoisCourant() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return {};

    final now    = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2,'0')}';

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: '$prefix-01')
        .where('date', isLessThanOrEqualTo:    '$prefix-31')
        .get();

    final Map<int, int> result = {};
    for (final doc in snap.docs) {
      final data = doc.data();
      final date = data['date'] as String;
      final day  = int.tryParse(date.split('-').last) ?? 0;
      result[day] = (data['minutesTotal'] ?? 0) as int;
    }
    return result;
  }

  // ── Top sourates du mois ──────────────────────────────────────────────────
  Future<List<Map<String, dynamic>>> getTopSourates({int limit = 5}) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return [];

    final now    = DateTime.now();
    final prefix = '${now.year}-${now.month.toString().padLeft(2,'0')}';

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where('date', isGreaterThanOrEqualTo: '$prefix-01')
        .where('date', isLessThanOrEqualTo:    '$prefix-31')
        .get();

    final Map<String, Map<String, dynamic>> aggregated = {};

    for (final doc in snap.docs) {
      final souratesMap = Map<String, dynamic>.from(
          (doc.data()['sourates'] ?? {}) as Map);

      souratesMap.forEach((key, val) {
        if (aggregated.containsKey(key)) {
          aggregated[key]!['minutes'] =
              (aggregated[key]!['minutes'] ?? 0) + ((val['minutes'] ?? 0) as int);
          aggregated[key]!['ecoutes'] =
              (aggregated[key]!['ecoutes'] ?? 0) + ((val['ecoutes'] ?? 0) as int);
        } else {
          aggregated[key] = {
            'titre':   val['nom'] ?? 'Sourate $key',
            'artiste': 'Mishary Rashid Alafasy',
            'minutes': (val['minutes'] ?? 0) as int,
            'ecoutes': (val['ecoutes'] ?? 0) as int,
          };
        }
      });
    }

    final liste = aggregated.values.toList()
      ..sort((a, b) => (b['ecoutes'] as int).compareTo(a['ecoutes'] as int));

    return liste.take(limit).toList();
  }

  // ── Total minutes du mois ─────────────────────────────────────────────────
  Future<int> getTotalMinutesMoisCourant() async {
    final parJour = await getMinutesParJourMoisCourant();
    return parJour.values.fold<int>(0, (a, b) => a + b);
  }
}