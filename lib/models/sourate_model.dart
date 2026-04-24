// ============================================================
//  lib/models/sourate_model.dart
// ============================================================

class Sourate {
  final int numero;
  final String nom;           // arabe
  final String nomAnglais;    // translittération
  final String traduction;    // traduction du nom
  final String type;          // Meccan / Medinan
  final int nbVersets;
  final String? audioUrl;

  Sourate({
    required this.numero,
    required this.nom,
    required this.nomAnglais,
    required this.traduction,
    required this.type,
    required this.nbVersets,
    this.audioUrl,
  });

  factory Sourate.fromJson(Map<String, dynamic> json, {String? audioUrl}) {
    return Sourate(
      numero:      json['number']                  ?? 0,
      nom:         json['name']                    ?? '',
      nomAnglais:  json['englishName']             ?? '',
      traduction:  json['englishNameTranslation']  ?? '',
      type:        json['revelationType']          ?? '',
      nbVersets:   json['numberOfAyahs']           ?? 0,
      audioUrl:    audioUrl,
    );
  }

  // Catégorie pour organiser la playlist
  String get categorie => type == 'Meccan' ? 'Mecquoises' : 'Médinoises';
}

class Favori {
  final String uid;
  final int numeroSourate;
  final String nomSourate;
  final String nomAnglais;
  final String audioUrl;
  final DateTime ajouteLe;

  Favori({
    required this.uid,
    required this.numeroSourate,
    required this.nomSourate,
    required this.nomAnglais,
    required this.audioUrl,
    required this.ajouteLe,
  });

  Map<String, dynamic> toFirestore() => {
    'uid':            uid,
    'numeroSourate':  numeroSourate,
    'nomSourate':     nomSourate,
    'nomAnglais':     nomAnglais,
    'audioUrl':       audioUrl,
    'ajouteLe':       ajouteLe.toIso8601String(),
  };

  factory Favori.fromFirestore(Map<String, dynamic> data) => Favori(
    uid:            data['uid']           ?? '',
    numeroSourate:  data['numeroSourate'] ?? 0,
    nomSourate:     data['nomSourate']    ?? '',
    nomAnglais:     data['nomAnglais']    ?? '',
    audioUrl:       data['audioUrl']      ?? '',
    ajouteLe: DateTime.tryParse(data['ajouteLe'] ?? '') ?? DateTime.now(),
  );
}