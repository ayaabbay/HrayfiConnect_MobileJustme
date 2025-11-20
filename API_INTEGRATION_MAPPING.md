# 🗺️ Cartographie Complète de l'Intégration API - HrayfiConnect

## Vue d'ensemble

Ce document mappe TOUTES les APIs backend avec leurs intégrations frontend correspondantes, identifie ce qui est connecté, ce qui manque, et les actions à prendre.

---

## 📊 Statistiques Globales

- **Total Endpoints Backend**: 61
- **Endpoints Connectés au Frontend**: ~25
- **Endpoints Non Utilisés**: ~36
- **Services Frontend**: 9
- **Services Manquants**: 2 (Chat Service, WebSocket Service)

---

## 1. 🔐 AUTHENTIFICATION (`/api/v1/auth`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/register/client` | POST | Inscription client | ✅ **Utilisé** - `auth_service.dart` |
| `/register/artisan` | POST | Inscription artisan | ✅ **Utilisé** - `auth_service.dart` |
| `/login` | POST | Connexion | ✅ **Utilisé** - `auth_service.dart` |
| `/me` | GET | Profil utilisateur connecté | ✅ **Utilisé** - `auth_service.dart` |
| `/refresh` | POST | Rafraîchir token | ❌ **Non utilisé** |
| `/logout` | POST | Déconnexion | ⚠️ **Partiellement** - `auth_service.dart` (logout local seulement) |
| `/forgot-password` | POST | Demande réinitialisation | ✅ **Utilisé** - `auth_service.dart` |
| `/verify-reset-code` | POST | Vérifier code réinitialisation | ❌ **Non utilisé** |
| `/reset-password` | POST | Réinitialiser mot de passe | ✅ **Utilisé** - `auth_service.dart` |
| `/check-email/{email}` | GET | Vérifier disponibilité email | ❌ **Non utilisé** |
| `/test` | GET | Test endpoint | ❌ **Non utilisé** |

### Pages Frontend Utilisant Auth

- ✅ `login_page.dart` - Utilise `AuthService.login()`
- ✅ `register_page.dart` - Utilise `AuthService.registerClient()` et `registerArtisan()`
- ✅ `client_profile_page.dart` - Utilise `AuthService.logout()` (local seulement)
- ✅ Toutes les pages avec authentification - Utilisent token via `StorageService`

### Actions Requises

1. ⚠️ **CRITIQUE**: Implémenter `/verify-reset-code` dans le flux de réinitialisation de mot de passe
2. ✅ Ajouter `/check-email` pour validation en temps réel lors de l'inscription
3. ✅ Implémenter `/refresh` pour renouvellement automatique du token

---

## 2. 👥 UTILISATEURS (`/api/v1/users`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/clients/` | GET | Liste des clients | ✅ **Utilisé** - `user_service.dart`, `admin_users_page.dart` |
| `/clients/{client_id}` | GET | Détails d'un client | ❌ **Non utilisé** |
| `/clients/{client_id}` | PUT | Mettre à jour un client | ✅ **Utilisé** - `user_service.dart` |
| `/clients/{client_id}` | DELETE | Supprimer un client | ❌ **Non utilisé** |
| `/artisans/` | GET | Liste des artisans | ✅ **Utilisé** - `user_service.dart`, `artisan_service.dart`, `client_home_page.dart` |
| `/artisans/{artisan_id}` | GET | Détails d'un artisan | ✅ **Utilisé** - `user_service.dart`, `artisan_service.dart`, `artisan_detail_page.dart` |
| `/artisans/{artisan_id}` | PUT | Mettre à jour un artisan | ❌ **Non utilisé** (mais nécessaire) |
| `/artisans/{artisan_id}/verify` | PUT | Vérifier un artisan | ✅ **Utilisé** - `artisan_service.dart`, `admin_users_page.dart` |
| `/profile` | GET | Profil utilisateur connecté | ✅ **Utilisé** - `user_service.dart` |
| `/artisans/search` | GET | Rechercher des artisans | ✅ **Utilisé** - `artisan_service.dart` |

### Pages Frontend Utilisant Users

- ✅ `client_home_page.dart` - Utilise `ArtisanService.getArtisans()` et `searchArtisans()`
- ✅ `artisan_detail_page.dart` - Utilise détails artisan
- ✅ `admin_users_page.dart` - Utilise `UserService.getClients()` et `getArtisans()`
- ✅ `admin_users_page.dart` - Utilise `ArtisanService.verifyArtisan()`
- ❌ `client_edit_profile_page.dart` - **NON CONNECTÉ** - Devrait utiliser `UserService.updateClient()`
- ❌ `artisan_portfolio_page.dart` - **NON CONNECTÉ** - Devrait utiliser update artisan

### Actions Requises

1. 🔴 **URGENT**: Connecter `client_edit_profile_page.dart` avec `UserService.updateClient()`
2. 🔴 **URGENT**: Créer service pour mettre à jour profil artisan
3. ✅ Implémenter `getClient()` pour voir détails client
4. ✅ Implémenter suppression client (admin)

---

## 3. 📅 RÉSERVATIONS (`/api/v1/bookings`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/` | POST | Créer une réservation | ✅ **Utilisé** - `booking_service.dart`, `booking_modal.dart` |
| `/my-bookings` | GET | Mes réservations | ✅ **Utilisé** - `booking_service.dart`, `client_booking_page.dart` |
| `/{booking_id}` | GET | Détails d'une réservation | ❌ **Non utilisé** |
| `/{booking_id}` | PUT | Mettre à jour une réservation | ✅ **Utilisé** - `booking_service.dart` |
| `/{booking_id}/schedule` | PUT | Modifier la date/heure | ❌ **Non utilisé** |
| `/{booking_id}/status` | PUT | Changer le statut | ✅ **Utilisé** - `booking_service.dart` |
| `/{booking_id}` | DELETE | Supprimer une réservation | ❌ **Non utilisé** |
| `/stats/me` | GET | Statistiques personnelles | ✅ **Utilisé** - `booking_service.dart` |
| `/debug/routes` | GET | Debug routes | ❌ **Non utilisé** |

### Pages Frontend Utilisant Bookings

- ✅ `client_booking_page.dart` - Utilise `BookingService.getMyBookings()`
- ✅ `booking_modal.dart` - Utilise `BookingService.createBooking()`
- ✅ `artisan_urgent_dashboard_page.dart` - **UI SEULEMENT** - Devrait utiliser bookings API
- ✅ `artisan_calendar_page.dart` - **UI SEULEMENT** - Devrait utiliser bookings API

### Actions Requises

1. 🔴 **URGENT**: Connecter `artisan_urgent_dashboard_page.dart` avec bookings API pour afficher vraies demandes
2. 🔴 **URGENT**: Connecter `artisan_calendar_page.dart` avec bookings API
3. ✅ Implémenter `getBooking()` pour voir détails d'une réservation
4. ✅ Implémenter `updateBookingSchedule()` pour changer date/heure
5. ✅ Implémenter suppression de réservation

---

## 4. 💬 CHAT (`/api/v1/chat`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/ws/chat` | WebSocket | Chat en temps réel | ❌ **NON IMPLÉMENTÉ** - Service manquant |
| `/conversations` | GET | Liste des conversations | ❌ **NON IMPLÉMENTÉ** - Service manquant |
| `/conversations/{booking_id}/messages` | GET | Messages d'une conversation | ❌ **NON IMPLÉMENTÉ** - Service manquant |
| `/conversations/{booking_id}/read` | POST | Marquer comme lu | ❌ **NON IMPLÉMENTÉ** - Service manquant |
| `/stats` | GET | Statistiques chat | ❌ **NON IMPLÉMENTÉ** - Service manquant |

### Pages Frontend Utilisant Chat

- ❌ `client_chat_list_page.dart` - **UI SEULEMENT** - Données mockées
- ❌ `chat_detail_page.dart` - **UI SEULEMENT** - Messages mockés
- ❌ `artisan_messages_page.dart` - **UI SEULEMENT** - Messages mockés

### Actions Requises

1. 🔴 **CRITIQUE**: Créer `chat_service.dart` avec toutes les méthodes
2. 🔴 **CRITIQUE**: Implémenter WebSocket client pour chat temps réel
3. 🔴 **CRITIQUE**: Connecter toutes les pages chat avec le service

---

## 5. ⭐ AVIS (`/api/v1/reviews`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/` | POST | Créer un avis | ❌ **Non utilisé** (UI existe mais pas connectée) |
| `/artisans/{artisan_id}` | GET | Avis d'un artisan | ✅ **Utilisé** - `review_service.dart` |
| `/my-reviews` | GET | Mes avis | ✅ **Utilisé** - `review_service.dart` |
| `/{review_id}` | GET | Détails d'un avis | ❌ **Non utilisé** |
| `/{review_id}` | PUT | Modifier un avis | ✅ **Utilisé** - `review_service.dart` |
| `/{review_id}` | DELETE | Supprimer un avis | ❌ **Non utilisé** |
| `/artisans/{artisan_id}/stats` | GET | Statistiques de notation | ✅ **Utilisé** - `review_service.dart` |

### Pages Frontend Utilisant Reviews

- ❌ `client_review_page.dart` - **UI SEULEMENT** - Pas connecté avec `ReviewService.createReview()`
- ✅ `artisan_detail_page.dart` - Devrait afficher reviews avec `getArtisanReviews()`
- ✅ `client_history_page.dart` - Devrait afficher reviews avec `getMyReviews()`

### Actions Requises

1. 🔴 **URGENT**: Connecter `client_review_page.dart` avec `ReviewService.createReview()`
2. ✅ Afficher reviews dans `artisan_detail_page.dart`
3. ✅ Implémenter suppression d'avis

---

## 6. 🎫 TICKETS (`/api/v1/tickets`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/` | POST | Créer un ticket | ✅ **Utilisé** - `ticket_service.dart` |
| `/my-tickets` | GET | Mes tickets | ✅ **Utilisé** - `ticket_service.dart` |
| `/` | GET | Tous les tickets (admin) | ✅ **Utilisé** - `ticket_service.dart`, `admin_tickets_page.dart` |
| `/{ticket_id}` | GET | Détails d'un ticket | ❌ **Non utilisé** |
| `/{ticket_id}` | PUT | Mettre à jour un ticket | ❌ **Non utilisé** |
| `/{ticket_id}/status` | PUT | Changer le statut (admin) | ✅ **Utilisé** - `ticket_service.dart`, `admin_tickets_page.dart` |
| `/{ticket_id}/responses` | POST | Ajouter une réponse | ✅ **Utilisé** - `ticket_service.dart` |
| `/{ticket_id}` | DELETE | Supprimer un ticket | ❌ **Non utilisé** |
| `/stats/overview` | GET | Statistiques (admin) | ❌ **Non utilisé** |
| `/stats/my-stats` | GET | Mes statistiques | ❌ **Non utilisé** |

### Pages Frontend Utilisant Tickets

- ✅ `client_ticket_page.dart` - Utilise `TicketService.createTicket()`
- ✅ `admin_tickets_page.dart` - Utilise `TicketService.getAllTickets()` et `updateTicketStatus()`
- ⚠️ `client_ticket_page.dart` - Devrait afficher `my-tickets` après création

### Actions Requises

1. ✅ Implémenter `getTicket()` pour voir détails
2. ✅ Implémenter `updateTicket()` pour modifier ticket
3. ✅ Implémenter suppression de ticket
4. ✅ Afficher statistiques tickets dans dashboard admin

---

## 7. 📤 UPLOAD (`/api/v1/upload`)

### Backend Endpoints

| Endpoint | Méthode | Description | Frontend Status |
|----------|---------|-------------|-----------------|
| `/profile-picture` | POST | Upload photo de profil | ✅ **Utilisé** - `upload_service.dart` |
| `/profile-picture` | DELETE | Supprimer photo de profil | ✅ **Utilisé** - `upload_service.dart` |
| `/artisans/identity-documents/{document_type}` | POST | Upload document identité | ❌ **Non utilisé** |
| `/artisans/{artisan_id}/identity-documents` | GET | Voir documents identité | ❌ **Non utilisé** |
| `/artisans/portfolio` | POST | Upload image portfolio | ✅ **Utilisé** - `upload_service.dart` |
| `/artisans/portfolio/{image_index}` | DELETE | Supprimer image portfolio | ✅ **Utilisé** - `upload_service.dart` |
| `/artisans/portfolio/multiple` | POST | Upload multiple images | ❌ **Non utilisé** |
| `/artisans/portfolio` | GET | Voir portfolio | ❌ **Non utilisé** |

### Pages Frontend Utilisant Upload

- ✅ `client_edit_profile_page.dart` - UI pour changer photo (pas connecté)
- ✅ `artisan_portfolio_page.dart` - UI pour portfolio (pas connecté)
- ❌ Pages d'upload documents identité - **Manquantes**

### Actions Requises

1. 🔴 **URGENT**: Connecter `client_edit_profile_page.dart` avec upload photo profil
2. 🔴 **URGENT**: Connecter `artisan_portfolio_page.dart` avec upload/delete portfolio
3. ✅ Créer page pour upload documents identité artisans
4. ✅ Implémenter upload multiple images portfolio

---

## 8. 📋 Endpoints Non Catégorisés / Manquants

### Endpoints Backend Non Trouvés dans l'Analyse

- Certains endpoints peuvent nécessiter une vérification supplémentaire

---

## 🚨 Priorités d'Intégration

### 🔴 Critique / Urgent

1. **Chat Service Complet**
   - Créer `chat_service.dart`
   - Implémenter WebSocket client
   - Connecter toutes les pages chat

2. **Pages Artisan Non Connectées**
   - `artisan_urgent_dashboard_page.dart` → Bookings API
   - `artisan_calendar_page.dart` → Bookings API
   - `artisan_portfolio_page.dart` → Upload API

3. **Pages Client Non Connectées**
   - `client_edit_profile_page.dart` → UserService + UploadService
   - `client_review_page.dart` → ReviewService

### ⚠️ Important

4. **Services Manquants**
   - Créer méthodes pour endpoints non utilisés
   - Implémenter gestion d'erreurs cohérente

5. **Améliorations UX**
   - Validation email en temps réel
   - Refresh token automatique
   - Gestion offline

### ✅ Nice to Have

6. **Fonctionnalités Avancées**
   - Statistiques complètes
   - Notifications push
   - Recherche avancée

---

## 📝 Notes Techniques

### Structure des Services Frontend

Tous les services doivent:
1. Utiliser `ApiService` pour les appels HTTP
2. Gérer les erreurs avec `ApiException`
3. Retourner des modèles typés
4. Gérer l'authentification automatiquement via `StorageService`

### Structure des Modèles

Les modèles frontend doivent correspondre exactement aux schémas backend:
- Utiliser les mêmes noms de champs (snake_case ↔ camelCase)
- Gérer les conversions de types (DateTime, ObjectId → String)
- Valider les données reçues

### Gestion d'Erreurs

Toutes les pages doivent:
1. Capturer `ApiException` pour erreurs API
2. Afficher messages d'erreur utilisateur-friendly
3. Gérer les états de chargement
4. Gérer les états vides

---

## 📊 Résumé des Connectivités

### ✅ Bien Connecté
- Authentification (sauf refresh et verify-reset-code)
- Réservations (création, liste, stats)
- Tickets (création, liste, update statut)
- Users (liste, recherche)
- Upload (photo profil, portfolio)

### ⚠️ Partiellement Connecté
- Reviews (UI existe mais création non connectée)
- Bookings (manque détails, schedule, delete)
- Tickets (manque détails, update, delete)
- Upload (manque portfolio GET, documents identité)

### ❌ Non Connecté
- **Chat complet** (aucun service)
- **Artisan dashboard** (données mockées)
- **Artisan calendar** (données mockées)
- **Profile edit** (UI seulement)
- **Review creation** (UI seulement)

---

## 🎯 Plan d'Action Recommandé

### Phase 1: Fonctionnalités Critiques (Semaine 1)
1. Créer ChatService complet
2. Connecter artisan dashboard avec bookings
3. Connecter artisan calendar avec bookings

### Phase 2: Fonctionnalités Importantes (Semaine 2)
1. Connecter profile edit
2. Connecter review creation
3. Compléter upload services

### Phase 3: Améliorations (Semaine 3)
1. Ajouter endpoints manquants dans services
2. Améliorer gestion d'erreurs
3. Ajouter validations

---

**Document créé le**: [Date actuelle]
**Dernière mise à jour**: [Date actuelle]
**Statut**: ✅ Analyse complète terminée

