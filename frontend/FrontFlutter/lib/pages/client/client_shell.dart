import 'package:flutter/material.dart';
import '../../services/storage_service.dart';
import 'client_home_page.dart';
import 'client_booking_page.dart';
import 'client_chat_list_page.dart';
import 'client_profile_page.dart';
//import '../../models/artisan.dart';

class ClientShell extends StatefulWidget {
  static const routeName = '/client';
  const ClientShell({super.key});

  @override
  State<ClientShell> createState() => _ClientShellState();
}

class _ClientShellState extends State<ClientShell> {
  int _currentIndex = 0;
  final _pages = const [
    ClientHomePage(),
    ClientBookingPage(),
    ClientChatListPage(),
    ClientProfilePage(),
  ];

  @override
  void initState() {
    super.initState();
    // Vérifier après la première frame que l'utilisateur est bien authentifié
    WidgetsBinding.instance.addPostFrameCallback((_) => _ensureAuthenticated());
  }

  Future<void> _ensureAuthenticated() async {
    final token = await StorageService.getToken();
    if (!mounted) return;

    if (token == null) {
      // Si le token n'existe plus (déconnexion), renvoyer vers la page de login
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/login',
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: _currentIndex == 0 
          ? null // Pas d'AppBar pour la page d'accueil (elle a sa propre barre de recherche)
          : AppBar(title: const Text('Espace Client')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.search), label: 'Recherche'),
          BottomNavigationBarItem(icon: Icon(Icons.event), label: 'Réservations'),
          BottomNavigationBarItem(icon: Icon(Icons.chat_bubble_outline), label: 'Chat'),
          BottomNavigationBarItem(icon: Icon(Icons.person_outline), label: 'Profil'),
        ],
      ),
    );
  }
}


