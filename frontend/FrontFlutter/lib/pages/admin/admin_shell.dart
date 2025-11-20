import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_users_page.dart';
import 'admin_services_page.dart';
import 'admin_tickets_page.dart';

class AdminShell extends StatefulWidget {
  static const routeName = '/admin';
  const AdminShell({super.key});

  @override
  State<AdminShell> createState() => _AdminShellState();
}

class _AdminShellState extends State<AdminShell> {
  int _currentIndex = 0;
  final _pages = const [
    AdminDashboardPage(),
    AdminUsersPage(),
    AdminServicesPage(),
    AdminTicketsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Administration')),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Utilisateurs'),
          BottomNavigationBarItem(icon: Icon(Icons.home_repair_service_outlined), label: 'Services'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Tickets'),
        ],
      ),
    );
  }
}


