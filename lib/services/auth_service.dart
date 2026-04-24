// ============================================================
//  lib/services/auth_service.dart
//  Toute la logique Firebase Auth + Firestore
// ============================================================

import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // État de connexion en temps réel (utilisé dans main.dart)
  Stream<User?> get authStateChanges => _auth.authStateChanges();
  User? get currentUser => _auth.currentUser;

  // ─── Inscription ─────────────────────────────────────────────────────────
  Future<UserCredential> register({
    required String email,
    required String password,
    required String nom,
    required String prenom,
    required DateTime dateNaissance,
  }) async {
    final age = _age(dateNaissance);
    if (age < 13) throw Exception('age_invalid');

    final cred = await _auth.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    await cred.user!.updateDisplayName('$prenom $nom');

    // Sauvegarde profil dans Firestore
    await _db.collection('users').doc(cred.user!.uid).set({
      'nom': nom,
      'prenom': prenom,
      'email': email,
      'dateNaissance': Timestamp.fromDate(dateNaissance),
      'createdAt': FieldValue.serverTimestamp(),
      'objectifMensuel': 20, // défaut 20h
    });

    return cred;
  }

  // ─── Connexion ────────────────────────────────────────────────────────────
  Future<UserCredential> login({
    required String email,
    required String password,
  }) async {
    return await _auth.signInWithEmailAndPassword(
        email: email, password: password);
  }

  // ─── Déconnexion ──────────────────────────────────────────────────────────
  Future<void> logout() async => await _auth.signOut();

  // ─── Reset mot de passe ───────────────────────────────────────────────────
  Future<void> resetPassword(String email) async {
    await _auth.sendPasswordResetEmail(email: email);
  }

  // ─── Profil Firestore ─────────────────────────────────────────────────────
  Future<Map<String, dynamic>?> getUserProfile() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return null;
    final doc = await _db.collection('users').doc(uid).get();
    return doc.data();
  }

  // ─── Calcul âge ───────────────────────────────────────────────────────────
  int _age(DateTime dob) {
    final now = DateTime.now();
    int age = now.year - dob.year;
    if (now.month < dob.month ||
        (now.month == dob.month && now.day < dob.day)) age--;
    return age;
  }
}