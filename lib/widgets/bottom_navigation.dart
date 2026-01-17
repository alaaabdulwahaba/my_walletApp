import 'package:flutter/material.dart';
import '../screens/home_screen.dart';
import '../screens/statistics_screen.dart';
import '../screens/cards_screen.dart';
import '../screens/settings_screen.dart';
import '../utils/app_colors.dart';

class BottomsNavigation extends StatefulWidget {
  @override
  _BottomsNavigationState createState() => _BottomsNavigationState();
}

class _BottomsNavigationState extends State<BottomsNavigation> {
  int _currentIndex = 0;

  // ترتيب الصفحات
  final List<Widget> _screens = [
    HomeScreen(),
    StatisticsScreen(),
    CardsScreen(), // Cards Management screen
    SettingScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppColors.surface,
        items: [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Home'),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: 'Stats'),
          BottomNavigationBarItem(icon: Icon(Icons.credit_card), label: 'Cards'),
          BottomNavigationBarItem(icon: Icon(Icons.settings), label: 'Settings'),
        ],
      ),
    );
  }
}
