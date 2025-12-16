# HrayfiConnect Mobile - Frontend Flutter

## Description
Application mobile multiplateforme pour la gestion des services d'artisans, clients et administrateurs.

## Fonctionnalités

### Pour les Clients
- Recherche et découverte d'artisans
- Réservation de services
- Système de chat en temps réel
- Gestion des avis et notes
- Suivi des réservations
- Gestion du profil

### Pour les Artisans
- Calendrier des réservations
- Gestion du portfolio
- Messagerie avec les clients
- Dashboard de demandes urgentes
- Gestion du profil professionnel

### Pour les Administrateurs
- Dashboard de gestion
- Gestion des utilisateurs
- Supervision des réservations
- Gestion des tickets support

## Structure du projet

\`\`\`
lib/
├── config/          # Configuration API
├── models/          # Modèles de données
├── pages/           # Écrans de l'application
│   ├── admin/       # Pages administrateur
│   ├── artisan/     # Pages artisan
│   ├── auth/        # Authentification
│   ├── chat/        # Messagerie
│   ├── client/      # Pages client
│   └── reviews/     # Avis et notations
├── providers/       # Gestion d'état
├── repositories/    # Couche données
├── services/        # Services API
├── theme/           # Thème de l'application
└── widgets/         # Composants réutilisables
\`\`\`

## Installation

1. Installer Flutter SDK (>=3.3.0)
2. Cloner le projet
3. Installer les dépendances :
\`\`\`bash
flutter pub get
\`\`\`

## Lancement

### Mode développement
\`\`\`bash
flutter run
\`\`\`

### Build production
\`\`\`bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
\`\`\`

## Configuration

Modifier l'URL de l'API dans [lib/config/api_config.dart](lib/config/api_config.dart)

## Dépendances principales

- **http**: Communication avec l'API REST
- **shared_preferences**: Stockage local
- **intl**: Internationalisation et formatage
- **image_picker**: Sélection d'images
- **web_socket_channel**: WebSocket pour le chat temps réel

## Tests

\`\`\`bash
flutter test
\`\`\`

## Architecture

L'application suit une architecture en couches :
- **Models**: Définition des structures de données
- **Services**: Communication avec l'API
- **Repositories**: Couche d'abstraction des données
- **Providers**: Gestion d'état
- **Pages**: Interface utilisateur

