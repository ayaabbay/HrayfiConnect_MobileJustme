import 'package:flutter/material.dart';
import 'artisan_urgent_dashboard_page.dart';
import 'artisan_messages_page.dart';
import 'artisan_calendar_page.dart';
import 'artisan_portfolio_page.dart';
import 'widgets/artisan_navbar.dart';

class ArtisanShell extends StatefulWidget {
  const ArtisanShell({Key? key}) : super(key: key);
  static const String routeName = '/artisan';
  @override
  State<ArtisanShell> createState() => _ArtisanShellState();
}

class _ArtisanShellState extends State<ArtisanShell> {
  String _currentPage = 'dashboard';
  int _urgentCount = 3; // Exemple: 3 demandes urgentes

  void _handlePageChange(String page) {
    setState(() {
      _currentPage = page;
    });
  }

  void _handleAcceptUrgent(String clientId) {
    setState(() {
      _urgentCount--;
    });
    // Logique pour accepter la demande urgente
  }

  void _handleDeclineUrgent(String clientId) {
    setState(() {
      _urgentCount--;
    });
    // Logique pour refuser la demande urgente
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: [
          ArtisanNavbar(
            urgentCount: _urgentCount,
            onTabSelected: _handlePageChange,
            currentTab: _currentPage,
          ),
          Expanded(
            child: _buildCurrentPage(),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentPage) {
      case 'dashboard':
        return ArtisanUrgentDashboardPage(
          onAcceptUrgent: _handleAcceptUrgent,
          onDeclineUrgent: _handleDeclineUrgent,
        );
      case 'messages':
        return ArtisanMessagesPage();
      case 'calendar':
        return ArtisanCalendarPage();
      case 'portfolio':
        return ArtisanPortfolioPage();
      default:
        return ArtisanUrgentDashboardPage(
          onAcceptUrgent: _handleAcceptUrgent,
          onDeclineUrgent: _handleDeclineUrgent,
        );
    }
  }
}