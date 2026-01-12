# Angers Connect 🏙️

Application mobile Flutter permettant de visualiser en temps réel les informations de la ville d'Angers : incidents routiers, parkings et lignes de transport en commun.

## 📱 Version

- **Flutter** : 3.6.1
- **Dart** : 3.10.1
- **SDK minimum** : ^3.10.1

## ✨ Fonctionnalités

### 🚧 Écran Incidents
- **Visualisation** : Carte interactive affichant tous les travaux et incidents en cours à Angers
- **Informations détaillées** :
  - Titre et description de l'incident
  - Adresse concernée
  - Dates de début et de fin des travaux
  - Impact sur la circulation (ralentissement, déviation)
  - Impact sur le tramway
  - Contact et email du service Info Travaux
- **Recherche** : Barre de recherche avec autocomplétion pour filtrer les incidents par titre
- **Favoris** : Système de sauvegarde des incidents favoris avec persistance locale
- **Géolocalisation** : Affichage de votre position en temps réel sur la carte (marqueur vert)
- **Navigation** : Zoom automatique sur l'incident sélectionné

### 🅿️ Écran Parkings
- **Deux types de parkings** :
  - Parkings vélo (affichés en rouge ou jaune)
  - Parkings voiture (affichés en bleu ou jaune)
- **Informations en temps réel** :
  - Disponibilité des places pour les parkings voiture
  - Capacité maximale et accès pour les parkings vélo
  - Date de dernière mise à jour
- **Recherche** : Barre de recherche avec autocomplétion
- **Favoris** : Sauvegarde des parkings préférés
- **Différenciation visuelle** : Les favoris apparaissent en jaune sur la carte
- **Géolocalisation** : Affichage de votre position en temps réel sur la carte (marqueur vert)

### 🚊 Écran Lignes Bus / Tram
- **Visualisation des lignes** :
  - 3 lignes de tramway (A, B, C) affichées par défaut
  - Nombreuses lignes de bus disponibles
  - Tracés colorés selon la ligne (couleurs officielles Irigo)
- **Filtrage intelligent** :
  - Bouton tramway pour sélectionner les lignes à afficher
  - Bouton bus avec tri optimisé (numériques, alphabétiques, mixtes)
  - Affichage dynamique des arrêts selon les lignes sélectionnées
- **Arrêts** :
  - Marqueurs pour tous les arrêts du réseau
  - Indication d'accessibilité PMR
  - Informations détaillées (code, nom, description, fuseau horaire)
- **Favoris** : Sauvegarde des arrêts favoris avec recentrage automatique
- **Géolocalisation** : Affichage de votre position en temps réel sur la carte (marqueur vert)

### 🌟 Fonctionnalités Transversales
- **Menu de navigation** : Drawer pour basculer entre les écrans
- **Système de favoris universel** :
  - Bouton étoile en haut de chaque écran pour accéder aux favoris
  - Bouton étoile dans chaque dialogue pour ajouter/retirer des favoris
  - Persistance des données avec SharedPreferences
  - Marqueurs jaunes sur la carte pour les éléments favoris
  - Recentrage automatique lors de la sélection d'un favori
- **Architecture BLoC** : Gestion d'état avec Cubit pour une séparation claire des responsabilités

## 🌐 API Utilisées

Toutes les données proviennent du portail Open Data de la ville d'Angers :

### 1. API Info Travaux
- **URL** : `https://data.angers.fr/api/records/1.0/search/?dataset=info-travaux`
- **Description** : Informations sur les travaux et événements en cours et à venir
- **Données** : Titre, description, adresse, dates, impact circulation, contact
- **Fréquence de mise à jour** : Quotidienne

### 2. API Parking Vélo
- **URL** : `https://data.angers.fr/api/explore/v2.1/catalog/datasets/parking-velo-angers/records`
- **Description** : Liste des parkings vélo de la ville
- **Données** : Nom, capacité, accès, coordonnées GPS, date de mise à jour

### 3. API Parking Voiture
- **URL** : `https://data.angers.fr/api/explore/v2.1/catalog/datasets/parking-angers/records`
- **Description** : Disponibilité en temps réel des parkings voiture
- **Données** : Nom du parking, nombre de places disponibles

### 4. API Lignes Irigo (GTFS)
- **URL** : `https://data.angers.fr/api/records/1.0/search/?dataset=irigo_gtfs_lines`
- **Description** : Lignes de transport du réseau Irigo
- **Données** : Identifiants, noms, couleurs, types (bus/tram), tracés géographiques

### 5. API Arrêts Irigo (GTFS)
- **URL** : `https://data.angers.fr/api/explore/v2.1/catalog/datasets/horaires-theoriques-et-arrets-du-reseau-irigo-gtfs/records`
- **Description** : Arrêts du réseau de transport
- **Données** : Codes, noms, descriptions, accessibilité, coordonnées GPS

### 6. OpenStreetMap Tiles
- **URL** : `https://tile.openstreetmap.org/{z}/{x}/{y}.png`
- **Description** : Tuiles cartographiques pour l'affichage des cartes
- **Licence** : Open Database License (ODbL)

## 🔐 Autorisations Nécessaires

### Android

L'application nécessite les permissions suivantes (configurées dans `AndroidManifest.xml`) :

- **INTERNET** : Obligatoire pour :
  - Récupérer les données des API Open Data
  - Charger les tuiles de la carte OpenStreetMap
  
- **ACCESS_FINE_LOCATION** : Optionnelle pour :
  - Afficher la position de l'utilisateur sur la carte
  - Améliorer l'expérience utilisateur avec un centrage automatique

- **ACCESS_COARSE_LOCATION** : Optionnelle pour :
  - Localisation approximative si la localisation précise n'est pas disponible


### Web

Aucune permission spécifique requise dans le code. Le navigateur demandera automatiquement l'autorisation de localisation via une popup.

**⚠️ Note importante sur la géolocalisation Web** :  
La géolocalisation fonctionne parfaitement sur **Android**. Sur **Web**, le comportement dépend des paramètres du navigateur :
- Si le navigateur autorise la géolocalisation et qu'elle fonctionne : le marqueur vert de position s'affiche
- Sinon : l'application continue de fonctionner normalement sans afficher d'erreur mais sans marqueur vert de position.

Pour activer la géolocalisation sur Web :
1. Cliquer sur "Autoriser" dans la popup du navigateur
2. Ou cliquer sur l'icône 🔒 dans la barre d'adresse → Localisation → Autoriser → Recharger (F5)

## 🏗️ Architecture

Le projet suit une architecture en couches claire et maintenable :

```
lib/
├── blocs/              # Gestion d'état avec Cubit
├── models/             # Modèles de données
├── repositories/       # Accès aux données (API)
├── services/           # Services (favoris, etc.)
└── ui/
    ├── screens/        # Écrans de l'application
    └── widgets/        # Composants réutilisables
```

### Patterns Utilisés
- **BLoC/Cubit** : Gestion d'état réactive
- **Repository Pattern** : Abstraction de la couche de données
- **Service Layer** : Logique métier réutilisable

## 📦 Dépendances Principales

```yaml
dependencies:
  flutter_bloc: ^9.1.1          # Gestion d'état
  http: ^1.1.0                  # Requêtes HTTP
  flutter_map: ^8.2.2           # Cartes interactives
  latlong2: ^0.9.1              # Coordonnées géographiques
  geolocator: ^9.0.2            # Géolocalisation
  shared_preferences: ^2.5.3    # Persistance locale
  path_provider: ^2.0.0         # Accès aux répertoires
```

## 🚀 Installation

1. **Cloner le projet**
```bash
git clone <url-du-repo>
cd angers_connect
```

2. **Installer les dépendances**
```bash
flutter pub get
```

3. **Lancer l'application**
```bash
# Android
flutter run

# Web
flutter run -d chrome
```

## 🧪 Tests

```bash
flutter test
```

## 📝 Licence

Ce projet utilise des données Open Data de la ville d'Angers sous licence **Open Database License (ODbL)**.

## 👨‍💻 Développement

**Framework** : Flutter  
**Langage** : Dart  
**État** : Fini  
**Plateforme cible** : Android, Web

---

*Projet réalisé dans le cadre du Semestre 9 - ESEO*
