import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/presentation/screens/portfolio/portfolio_screen.dart';
import 'package:finans_app/presentation/screens/finance/finance_screen.dart';
import 'package:finans_app/presentation/screens/tools/tools_screen.dart';
import 'dashboard_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;
  
  // Flattened the list into a getter or inside build to access setState
  List<Widget> get _screens => [
    DashboardView(
      onNavigateToTab: (index) {
        setState(() {
          _currentIndex = index;
        });
      },
    ),
    const PortfolioScreen(),
    const FinanceScreen(),
    const ToolsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    // We access the getter here. 
    // Note: Creating new widgets on every build is generally fine for these lightweight wrappers.
    // If state preservation is needed, we would need a different approach (e.g. PageView or IndexedStack).
    final screens = _screens; 

    return Scaffold(
      body: screens[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceDark,
        selectedItemColor: AppTheme.primaryColor,
        unselectedItemColor: AppTheme.textDim,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.dashboard), label: 'Özet'),
          BottomNavigationBarItem(icon: Icon(Icons.pie_chart), label: 'Portföy'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Finans'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Araçlar'),
        ],
      ),
    );
  }
}
