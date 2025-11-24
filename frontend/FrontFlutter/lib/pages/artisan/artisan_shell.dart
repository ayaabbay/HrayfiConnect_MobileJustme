import 'package:flutter/material.dart';
import 'artisan_urgent_dashboard_page.dart';
import 'artisan_messages_page.dart';
import 'artisan_calendar_page.dart';
import 'artisan_portfolio_page.dart';

class ArtisanShell extends StatefulWidget {
  const ArtisanShell({Key? key}) : super(key: key);
  static const String routeName = '/artisan';
  @override
  State<ArtisanShell> createState() => _ArtisanShellState();
}

class _ArtisanShellState extends State<ArtisanShell> {
  late final List<Widget> _pages;
  int _currentIndex = 0;
  int _urgentCount = 0;

  void _handleAcceptUrgent(String clientId) {
    setState(() {
      _urgentCount = (_urgentCount - 1).clamp(0, 999);
    });
    // Logique pour accepter la demande urgente
  }

  void _handleDeclineUrgent(String clientId) {
    setState(() {
      _urgentCount = (_urgentCount - 1).clamp(0, 999);
    });
    // Logique pour refuser la demande urgente
  }

  void _handleUrgentCountChanged(int count) {
    if (_urgentCount != count) {
      setState(() {
        _urgentCount = count;
      });
    }
  }

  @override
  void initState() {
    super.initState();
    _pages = [
      ArtisanUrgentDashboardPage(
        onAcceptUrgent: _handleAcceptUrgent,
        onDeclineUrgent: _handleDeclineUrgent,
        onUrgentCountChanged: _handleUrgentCountChanged,
      ),
      const ArtisanMessagesPage(),
      const ArtisanCalendarPage(),
      const ArtisanPortfolioPage(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: [
          BottomNavigationBarItem(
            icon: _buildDashboardIcon(),
            label: 'Dashboard',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.message_outlined),
            label: 'Messages',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            label: 'Calendrier',
          ),
          const BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            label: 'Portfolio',
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardIcon() {
    if (_urgentCount <= 0) {
      return const Icon(Icons.dashboard_outlined);
    }
    return Stack(
      clipBehavior: Clip.none,
      children: [
        const Icon(Icons.dashboard_outlined),
        Positioned(
          top: -2,
          right: -6,
          child: Container(
            padding: const EdgeInsets.all(4),
            decoration: const BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
            ),
            child: Text(
              _urgentCount.toString(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ],
    );
  }
}