# HrayfiConnect - Plateforme de Mise en Relation Artisans & Clients

<div align="center">

![Flutter](https://img.shields.io/badge/Flutter-3.3+-blue?logo=flutter)
![Python](https://img.shields.io/badge/Python-3.10+-green?logo=python)
![FastAPI](https://img.shields.io/badge/FastAPI-0.104+-orange?logo=fastapi)
![MongoDB](https://img.shields.io/badge/MongoDB-4.5+-green?logo=mongodb)
![Cloudinary](https://img.shields.io/badge/Cloudinary-1.38+-blue?logo=cloudinary)
![License](https://img.shields.io/badge/License-MIT-blue)

Une application mobile multiplateforme pour connecter artisans et clients, avec système de réservation, messagerie en temps réel et gestion administrative.

[Démarrage Rapide](#démarrage-rapide) | [Fonctionnalités](#fonctionnalités) | [Architecture](#architecture) | [Documentation](#documentation) | [Technologies](#technologies-complètes)

</div>

---

## Vue d'ensemble

**HrayfiConnect** est une plateforme complète permettant:
- **Clients** : Trouver des artisans qualifiés, réserver des services, échanger en temps réel
- **Artisans** : Gérer leurs services, calendrier et interactions clients
- **Administrateurs** : Superviser l'écosystème, modérer, gérer les utilisateurs

---

## Démarrage Rapide

### Prérequis

#### Backend
- Python 3.10+
- MongoDB 4.5+
- pip

#### Frontend  
- Flutter SDK 3.3.0+
- Xcode 14+ (macOS/iOS) ou Android Studio (Android)
- macOS 12+

### Installation Backend

```bash
# 1. Accédez au répertoire backend
cd backend/HrayfiConnect_Mobile/artisan-platform

# 2. Créez et activez l'environnement virtuel
python3 -m venv env
source env/bin/activate

# 3. Installez les dépendances
pip install -r requirements.txt

# 4. Configurez MongoDB
# Assurez-vous que MongoDB est en cours d'exécution
# macOS: brew services start mongodb-community

# 5. Lancez le serveur
python run.py
```

Le backend s'exécutera sur `http://localhost:8000`

### Installation Frontend

```bash
# 1. Accédez au répertoire frontend
cd frontend/FrontFlutter

# 2. Obtenez les dépendances
flutter pub get

# 3. Nettoyez (important pour la première fois)
flutter clean

# 4. Lancez l'application
flutter run

# Ou choisissez une plateforme spécifique:
# flutter run -d iphone      # iOS Simulator
# flutter run -d android     # Android Emulator
# flutter run -d chrome      # Web
# flutter run -d macos       # macOS Desktop
```

---

## Fonctionnalités

### Authentification
- Inscription (Clients & Artisans)
- Connexion/Déconnexion
- Récupération de mot de passe
- Gestion de sessions avec JWT
- Refresh token automatique

### Clients
- Recherche et découverte d'artisans
- Filtrage par catégorie, localité, évaluation
- Consultation des profils artisans
- Réservation de services
- Suivi des réservations
- Avis et notation des artisans
- Messagerie en temps réel (WebSocket)
- Gestion du profil

### Artisans
- Gestion du profil professionnel
- Portfolio de services
- Calendrier de disponibilités
- Gestion des réservations (accepter/refuser)
- Dashboard des demandes urgentes
- Messagerie avec les clients
- Historique des évaluations
- Statistiques personnelles

### Administration
- Dashboard système
- Gestion complète des utilisateurs
- Modération des contenus
- Gestion des catégories de services
- Supervision des réservations
- Gestion des tickets support
- Statistiques globales
- Vérification des artisans

---

## Architecture

### Stack Technique

```
CLIENTS MOBILES
Flutter (iOS, Android, Web, macOS)
              |
         [HTTP + WebSocket]
              |
BACKEND API
FastAPI + Uvicorn + CORS + JWT
              |
    +---------+---------+---------+
    |         |         |         |
  MongoDB  Cloudinary  WebSocket  Email
 (Donnees)  (Images)   (Chat)   (SMTP)
```

### Structure des Répertoires

```
HrayfiConnect_MobileJustme/
│
├── 📁 backend/
│   └── HrayfiConnect_Mobile/artisan-platform/
│       ├── run.py                    # Point d'entrée du serveur
|
+-- backend/
|   +-- HrayfiConnect_Mobile/artisan-platform/
|       +-- run.py                    (Point d'entree du serveur)
|       +-- requirements.txt          (Dependances Python)
|       +-- app/
|           +-- main.py              (Configuration FastAPI)
|           +-- api/
|           |   +-- v1/
|           |       +-- endpoints/   (Routes: auth, users, bookings, etc.)
|           |       +-- api.py       (Router principal)
|           |       +-- websockets/  (WebSocket pour chat)
|           +-- models/              (Modeles MongoDB + Pydantic)
|           +-- schemas/             (Schemas de validation)
|           +-- services/            (Logique metier)
|           +-- core/
|           |   +-- database.py      (Connexion MongoDB Motor)
|           |   +-- cloudinary_config.py
|           |   +-- security.py      (JWT, Hachage)
|           +-- utils/               (Utilitaires)
|
+-- frontend/
|   +-- FrontFlutter/
|       +-- pubspec.yaml             (Configuration Flutter)
|       +-- lib/
|       |   +-- main.dart            (Point d'entree)
|       |   +-- config/
|       |   |   +-- api_config.dart  (URL API selon plateforme)
|       |   +-- models/              (Auth, User, Artisan, Booking, etc.)
|       |   +-- pages/
|       |   |   +-- auth/            (Login, Register)
|       |   |   +-- client/          (Home, Search, Profile)
|       |   |   +-- artisan/         (Portfolio, Calendar, Dashboard)
|       |   |   +-- admin/           (Users Management, Dashboard)
|       |   |   +-- chat/            (Messages, Conversations)
|       |   |   +-- reviews/         (List, Form)
|       |   +-- services/
|    |   |   +-- api_service.dart      (HTTP calls)
|       |   |   +-- auth_service.dart     (Auth)
|       |   |   +-- artisan_service.dart  (Artisans)
|       |   |   +-- booking_service.dart  (Reservations)
|       |   |   +-- chat_service.dart     (Messaging)
|       |   |   +-- review_service.dart   (Reviews)
|       |   |   +-- user_service.dart     (Users)
|       |   |   +-- storage_service.dart  (LocalStorage)
|       |   |   +-- upload_service.dart   (File upload)
|       |   |   +-- admin_service.dart    (Admin)
|       |   |   +-- ticket_service.dart   (Support)
|       |   +-- repositories/        (Data layer)
|       |   +-- providers/           (State management)
|       |   +-- theme/               (AppTheme)
|       |   +-- widgets/             (Composants reutilisables)
|       +-- android/                 (Config Android)
|       +-- ios/                     (Config iOS)
|       +-- pubspec.lock             (Lock file)
|
+-- .git/                             (Version control)
+-- README.md                         (Ce fichier)
## 🔌 API Endpoints

### Base URL
`http://localhost:8000/api/v1`

### Authentification
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/auth/register/client` | Inscription client |
| `POST` | `/auth/register/artisan` | Inscription artisan |
| `POST` | `/auth/login` | Connexion |
| `GET` | `/auth/me` | Profil utilisateur connecté |
| `POST` | `/auth/forgot-password` | Demander réinitialisation |
| `POST` | `/auth/reset-password` | Réinitialiser mot de passe |

### Utilisateurs
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `GET` | `/users/clients/` | Liste des clients |
| `GET` | `/users/artisans/` | Liste des artisans |
| `GET` | `/users/artisans/{id}` | Détails d'un artisan |
| `GET` | `/users/artisans/search?q=...` | Rechercher artisans |
| `PUT` | `/users/clients/{id}` | Mettre à jour profil client |
| `PUT` | `/users/artisans/{id}/verify` | Vérifier artisan (admin) |

### Réservations
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/bookings/` | Créer une réservation |
| `GET` | `/bookings/my-bookings` | Mes réservations |
| `PUT` | `/bookings/{id}` | Mettre à jour réservation |
| `PUT` | `/bookings/{id}/status` | Changer statut |
| `GET` | `/bookings/stats/me` | Statistiques personnelles |

### Chat
| Mode | Endpoint | Description |
|---------|----------|-------------|
| `WS` | `/chat/ws/{user_id}` | WebSocket chat |
| `GET` | `/chat/messages/{user_id}` | Historique messages |

### Avis & Évaluations
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/reviews/` | Créer un avis |
| `GET` | `/reviews/artisan/{artisan_id}` | Avis d'un artisan |
| `PUT` | `/reviews/{id}` | Mettre à jour un avis |

### Support & Tickets
| Méthode | Endpoint | Description |
|---------|----------|-------------|
| `POST` | `/tickets/` | Créer un ticket |
| `GET` | `/tickets/my-tickets` | Mes tickets |
| `PUT` | `/tickets/{id}/status` | Changer statut ticket |

---

## Authentification & Sécurité

### JWT Token
```bash
# Token inclus dans les headers
Authorization: Bearer <token>

# Refresh token
POST /auth/refresh
```

### Hachage des Mots de Passe
- Algorithme: **bcrypt**
- Salt rounds: 12

### CORS
- Origines autorisées: `["*"]` (développement)
- À restreindre en production

---

## 📊 Base de Données

### MongoDB Collections

```javascript
// Users (Clients)
{
  _id: ObjectId,
  email: string,
  full_name: string,
  phone: string,
  location: string,
  profile_photo: string,
  created_at: Date
}

// Users (Artisans)
{
  _id: ObjectId,
  email: string,
  full_name: string,
  speciality: string,
  bio: string,
  rating: number,
  is_verified: boolean,
  portfolio: [string],
  availability: Object,
  created_at: Date
}

// Bookings
{
  _id: ObjectId,
  client_id: ObjectId,
  artisan_id: ObjectId,
  service_date: Date,
  status: enum,
  price: number,
  created_at: Date
}

// Messages
{Développementte Management: Provider Pattern
HTTP Client: http package
Storage Local: shared_preferences
WebSocket: web_socket_channel
Image Picker: image_picker
Intl: Internationalization
```

### Technologies Backend

```yaml
Language: Python 3.10+
Framework: FastAPI 0.104+
Server: Uvicorn 0.24+
ORM: Motor (async MongoDB driver)
Validation: Pydantic 2.5+
Authentication: Python-Jose + JWT
Password Hashing: Bcrypt
Media Upload: Cloudinary
WebSocket: websockets
Email: email-validator
```

---

## 📝 Configuration

### Backend (.env)
```bash
# MongoDB
MONGODB_URL=mongodb://localhost:27017
DATABASE_NAME=hrayficonnect

# Cdinary
CLOUDINARY_CLOUD_NAME=your_cloud_name
CLOUDINARY_API_KEY=your_api_key
CLOUDINARY_API_SECRET=your_api_secret

# JWT
SECRET_KEY=your_secret_key
ALGORITHM=HS256
ACCESS_TOKEN_EXPIRE_MINUTES=30

# CORS
ALLOWED_ORIGINS=http://localhost:3000,http://localhost:8080
```

### Frontend (lib/config/api_config.dart)
```dart
class ApiConfig {
  static String get baseUrl {
    // Configuration selon la plateforme
    if (kIsWeb) return 'http://localhost:8000';
    if (Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }
  
  static const String apiPrefix = '/api/v1';
}
```

---

## 🚀 Déploiement

### Backend (Heroku/Railway)
```bash
# Créer Procfile
echo "web: uvicorn app.main:app --host 0.0.0.0 --port \$PORT" > Procfile

# Déployer
gitsh heroku main
```

### Frontend (PlayStore/AppStore)
```bash
# Build APK (Android)
flutter build apk --release

# Build iOS
flutter build ios --release

# Build Web
flutter build web --release
```

---

## 🐛 Troubleshooting

| Problème | Solution |
|----------|----------|
| Connection refused | Vérifiez que le backend est lancé sur le port 8000 |
| MongoDB connection error | Démarrez MongoDB: `brew services start mongodb-community` |
| CORS error | Vérifiez les origins autorisées dans `main.py` |
| API 404 | Vérifiez l'URL API dans `api_config.dart` |
| Wocket connection failed | Assurez-vous que le backend est en cours d'exécution |
| Flutter doctor errors | Exécutez `flutter doctor` et suivez les instructions |

---

## 📚 Documentation

- [Backend API Documentation](backend/HrayfiConnect_Mobile/README_BACKEND.md)
- [Frontend Architecture](frontend/FrontFlutter/README_FRONTEND.md)
- [Database Schema](docs/DATABASE_SCHEMA.md)
- [API Integration Guide](docs/API_INTEGRATION.md)

---

## 🤝 Contribution

Les contributions sont bienvenues! Veuillez:

1. Fork le projet
2. Créer une branche (`git checkout -b feature/AmazingFeature`)
3. Commit les changements (`git commit -m 'Add AmazingFeature'`)
4. Push vers la branche (`git push origin feature/AmazingFeature`)
5. rir une Pull Request

---

## 📄 License

Ce projet est sous license **MIT**. Voir [LICENSE](LICENSE) pour plus de détails.

---

## 👥 Équipe

- *ckend Lead** : Développement FastAPI/MongoDB
- **Frontend Lead** : Développement Flutter
- **DevOps** : Déploiement et infrastructure

---

## Support

Pour de l'aide:
- 📧 Email: support@hrayficonnect.com
- 💬 Discord: [HrayfiConnect Server](https://discord.gg/hrayficonnect)
- 🐛 Issues: [GitHub Issues](https://github.com/hrayficonnect/issues)

---

## 📈 Roadmap

- [ ] Intégration paiement en ligne (Stripe)
- [ ] Notifications push
- [Roadmap

- [ ] Intégration paiement en ligne (Stripe)
- [ ] Notifications push
- [ ] Système de recommandation IA
- [ ] Statistiques avancées
- [ ] Internationalisation complète (i18n)
- [ ] Mode hors ligne
- [ ] Video call intégrée
- [ ] Programme de fidélité

---

## Technologies Completes

### FRONTEND - FLUTTER

Langage: Dart 3.0+
Framework: Flutter 3.3+
UI Kit: Material Design 3

Dependances principales:
- flutter: SDK de base
- http: 1.1.0 (Requetes HTTP)
- shared_preferences: 2.2.2 (Stockage local)
- intl: 0.19.0 (Internationalisation)
- image_picker: 1.0.7 (Selection images)
- web_socket_channel: 2.4.0 (WebSocket - Chat realtime)
- cupertino_icons: 1.0.8 (Icones iOS)

Dev Dependencies:
- flutter_test: SDK
- flutter_lints: 4.0.0 (Linting)

### BACKEND - FASTAPI + PYTHON

Langage: Python 3.10+
Framework: FastAPI 0.104+
Server: Uvicorn 0.24+
Port: 8000

Dependances principales:
- fastapi: 0.104+ (Framework web)
- uvicorn: 0.24+ (Serveur ASGI)
- motor: 3.3+ (Async MongoDB driver)
- pymongo: 4.5+ (Driver MongoDB)
- bcrypt: 4.0+ (Hachage mots de passe)
- python-jose: 3.3+ (JWT tokens)
- passlib: 1.7.4 (Password hashing utility)
- cryptography: 41.0+ (Chiffrement)
- pydantic: 2.5+ (Validation donnees)
- pydantic-settings: 2.1+ (Configuration)
- email-validator: 2.0+ (Validation emails)
- python-multipart: 0.0.6 (Upload fichiers)
- PyJWT: 2.8+ (JWT handling)
- cloudinary: 1.38+ (Gestion images/media)
- websockets: 10.0+ (WebSocket support)

### SERVICES EXTERNES

Cloudinary API: 1.38+
- Stockage et delivery d'images
- Compression automatique
- Gestion des assets media
- CDN global

MongoDB: 4.5+
- Base de donnees NoSQL
- Collections pour Users, Bookings, Messages, Reviews, etc.
- Indexation pour queries optimisees

### AUTHENTIFICATION & SECURITE

Authentification: JWT (JSON Web Tokens)
- Algoritme: HS256
- Token expiration: Configurable
- Refresh token: Support

Hachage: Bcrypt (salt rounds: 12)
- Mots de passe securises
- Comparaison sécurisée

CORS: Activé pour toutes origines (dev mode)
- A restreindre en production

### PLATFORMS SUPPORTEES

Frontend:
- iOS 12+ (via Xcode)
- Android 5.0+ (API 21+)
- Web (Chrome, Firefox, Safari)
- macOS 10.14+

Backend:
- Linux (Heroku, Railway, AWS)
- macOS
- Windows (via WSL)

---

Construit avec dedication pour connecter artisans et clients

Si ce projet vous plait, donnez une star!
