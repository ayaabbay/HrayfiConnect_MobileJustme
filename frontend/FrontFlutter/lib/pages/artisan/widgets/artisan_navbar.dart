import 'package:flutter/material.dart';

class ArtisanNavbar extends StatelessWidget {
  final int urgentCount;
  final Function(String) onTabSelected;
  final String currentTab;

  const ArtisanNavbar({
    Key? key,
    required this.urgentCount,
    required this.onTabSelected,
    required this.currentTab,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 8, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        children: [
          // Logo
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [Colors.blue, Colors.purple]),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.handyman, color: Colors.white, size: 24),
              ),
              SizedBox(width: 12),
              Text(
                "Artisan Pro",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue),
              ),
            ],
          ),
          
          Spacer(),
          
          // Boutons navigation
          _buildNavButton("Dashboard", Icons.dashboard, "dashboard", urgentCount),
          SizedBox(width: 8),
          _buildNavButton("Messages", Icons.message, "messages"),
          SizedBox(width: 8),
          _buildNavButton("Calendrier", Icons.calendar_today, "calendar"),
          SizedBox(width: 8),
          _buildNavButton("Portfolio", Icons.work, "portfolio"),
        ],
      ),
    );
  }

  Widget _buildNavButton(String text, IconData icon, String tab, [int? badgeCount]) {
    bool isSelected = currentTab == tab;
    return Stack(
      children: [
        ElevatedButton.icon(
          onPressed: () => onTabSelected(tab),
          icon: Icon(icon, size: 20),
          label: Text(text),
          style: ElevatedButton.styleFrom(
            backgroundColor: isSelected ? Colors.blue : Colors.grey[200],
            foregroundColor: isSelected ? Colors.white : Colors.grey[700],
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        if (badgeCount != null && badgeCount > 0)
          Positioned(
            top: 4,
            right: 4,
            child: Container(
              padding: EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              child: Text(
                badgeCount.toString(),
                style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ),
      ],
    );
  }
}