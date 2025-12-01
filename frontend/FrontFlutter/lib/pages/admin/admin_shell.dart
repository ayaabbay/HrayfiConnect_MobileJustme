import 'package:flutter/material.dart';
import 'admin_dashboard_page.dart';
import 'admin_users_page.dart';
import 'admin_tickets_page.dart';
import 'admin_bookings_page.dart';

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
    AdminBookingsPage(),
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
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard_outlined), label: 'Dashboard'),
          BottomNavigationBarItem(icon: Icon(Icons.people_outline), label: 'Utilisateurs'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today_outlined), label: 'Réservations'),
          BottomNavigationBarItem(icon: Icon(Icons.support_agent), label: 'Tickets'),
        ],
      ),
    );
  }
}


