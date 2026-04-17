# 🎵 Audio App - Flutter & Firebase

Application mobile de lecture audio avec authentification biométrique, statistiques d’écoute et gestion des favoris.  
Projet réalisé dans le cadre du cours **Développement Mobile (ING3 SEC)** à l’USTHB.

## 🚀 Fonctionnalités principales

- 🔐 Authentification biométrique par empreinte digitale au premier lancement
- 📱 Création de compte, connexion, réinitialisation de mot de passe (Firebase Auth)
- 👤 Champs obligatoires : nom, prénom, date de naissance (âge ≥ 13 ans)
- 📊 Page des statistiques :
  - Message de bienvenue personnalisé
  - Nombre total d’heures/minutes écoutées
  - Histogramme des minutes écoutées par jour (mois en cours)
  - Top des morceaux les plus écoutés
  - Barre de progression vers un objectif mensuel (modifiable)
- 🎧 Lecteur audio :
  - Playlist dynamique via API externe
  - Lecture en arrière-plan
  - Contrôles : lecture, pause, répétition
- ⭐ Favoris :
  - Sauvegarde en ligne (Firebase)
  - Suppression sécurisée par empreinte digitale
- 💾 Objectif mensuel sauvegardé localement

## 🛠️ Technologies utilisées

| Technologie         | Rôle                          |
|---------------------|-------------------------------|
| Flutter             | Frontend mobile               |
| Firebase Auth       | Authentification utilisateur  |
| Cloud Firestore     | Sauvegarde des favoris        |
| SharedPreferences   | Stockage local objectif       |
| Local Audio (ou API externe) | Playlist et métadonnées |
| `local_auth`        | Authentification biométrique  |
| `audio_service`     | Lecture en arrière-plan       |
| `fl_chart`          | Graphiques (histogramme)      |

## 📦 Installation

1. Cloner le dépôt :
   ```bash
   git clone https://github.com/ton-utilisateur/audio-app.git
   cd audio-app
