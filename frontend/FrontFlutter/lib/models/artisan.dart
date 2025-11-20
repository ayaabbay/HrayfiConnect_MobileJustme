// MODÈLE POUR PARTIE CLIENT
class Artisan {
  final String id;
  final String firstName;
  final String lastName;
  final String trade;
  final String? location;
  final String? description;
  final double? rating;
  final int? yearsOfExperience;
  final String avatar;
  final String photoUrl;
  final bool isCertified;
  final bool isVerified;
  final List<String> certifications;
  final String? companyName;
  final String? phone;
  final String? email;

  Artisan({
    required this.id,
    required this.firstName,
    required this.lastName,
    required this.trade,
    this.location,
    this.description,
    this.rating,
    this.yearsOfExperience,
    required this.avatar,
    required this.photoUrl,
    this.isCertified = false,
    this.isVerified = false,
    this.certifications = const [],
    this.companyName,
    this.phone,
    this.email,
  });

  String get fullName => '$firstName $lastName';
}

// Données d'exemple pour tests PARTIE CLIENT
List<Artisan> mockClientArtisans = [
  Artisan(
    id: '1',
    firstName: 'Amine',
    lastName: 'Elkarmi',
    trade: 'Électricien',
    location: 'Casablanca',
    description: 'Électricien professionnel avec 10 ans d\'expérience. Spécialisé dans les installations domestiques et industrielles.',
    rating: 4.8,
    yearsOfExperience: 10,
    avatar: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
    photoUrl: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=200&h=200&fit=crop',
    isCertified: true,
    isVerified: true,
    certifications: ['Certification Électricien', 'Sécurité Électrique', 'Normes NFC15-100'],
    companyName: 'Électricité Martin',
    phone: '+212694612891',
    email: 'karmi0amine@gmail.com',
  ),
  Artisan(
    id: '2',
    firstName: 'Sarah',
    lastName: 'Martin',
    trade: 'Plombier',
    location: 'Rabat',
    description: 'Plombier qualifié pour tous types de réparations et installations sanitaires.',
    rating: 4.6,
    yearsOfExperience: 8,
    avatar: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop',
    photoUrl: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=200&h=200&fit=crop',
    isCertified: true,
    isVerified: true,
    certifications: ['Certification Plomberie', 'Installation Sanitaire'],
    companyName: 'Plomberie Pro',
    phone: '+212612345678',
    email: 'sarah.martin@example.com',
  ),
  Artisan(
    id: '3',
    firstName: 'Hassan',
    lastName: 'Tazi',
    trade: 'Menuisier',
    location: 'Marrakech',
    description: 'Menuisier spécialisé en mobilier sur mesure et rénovation bois.',
    rating: 4.9,
    yearsOfExperience: 12,
    avatar: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop',
    photoUrl: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=200&h=200&fit=crop',
    isCertified: true,
    isVerified: true,
    certifications: ['Ébénisterie', 'Travail du Bois'],
    companyName: 'Menuiserie Tazi',
    phone: '+212698765432',
    email: 'hassan.tazi@example.com',
  ),
  Artisan(
    id: '4',
    firstName: 'Leila',
    lastName: 'Chraibi',
    trade: 'Peintre',
    location: 'Tanger',
    description: 'Peintre en bâtiment, rénovation et décoration intérieure et extérieure.',
    rating: 4.7,
    yearsOfExperience: 6,
    avatar: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop',
    photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=200&h=200&fit=crop',
    isCertified: false,
    isVerified: true,
    certifications: ['Peinture Décorative'],
    companyName: 'Peinture Chraibi',
    phone: '+212612345679',
    email: 'leila.chraibi@example.com',
  ),
  Artisan(
    id: '5',
    firstName: 'Omar',
    lastName: 'Fassi',
    trade: 'Électricien',
    location: 'Casablanca',
    description: 'Électricien industriel et domestique avec 15 ans d\'expérience.',
    rating: 4.5,
    yearsOfExperience: 15,
    avatar: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop',
    photoUrl: 'https://images.unsplash.com/photo-1472099645785-5658abf4ff4e?w=200&h=200&fit=crop',
    isCertified: true,
    isVerified: true,
    certifications: ['Électricité Industrielle', 'Domotique'],
    companyName: 'Fassi Électricité',
    phone: '+212600000000',
    email: 'omar.fassi@example.com',
  ),
  Artisan(
    id: '6',
    firstName: 'Karim',
    lastName: 'Benjelloun',
    trade: 'Plâtrier',
    location: 'Fès',
    description: 'Spécialiste en plâtrerie, faux plafonds et cloisonnement.',
    rating: 4.4,
    yearsOfExperience: 7,
    avatar: 'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=200&h=200&fit=crop',
    photoUrl: 'https://images.unsplash.com/photo-1519244703995-f4e0f30006d5?w=200&h=200&fit=crop',
    isCertified: true,
    isVerified: false,
    certifications: ['Plâtrerie Moderne'],
    companyName: 'Plâtrerie Karim',
    phone: '+212611111111',
    email: 'karim.benjelloun@example.com',
  ),
];