import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/presentation/screens/portfolio/portfolio_screen.dart';
import 'package:finans_app/presentation/screens/finance/finance_screen.dart';
import 'package:finans_app/presentation/screens/market/market_screen.dart';
import 'package:finans_app/presentation/screens/tools/tools_screen.dart';
import 'dashboard_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _selectedTab = 0;

  // Her sekme için ayrı bir navigasyon anahtarı
  final List<GlobalKey<NavigatorState>> _navigatorKeys = [
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
    GlobalKey<NavigatorState>(),
  ];

  void _onTabTapped(int index) {
    if (_selectedTab == index) {
      // Aynı sekmeye tekrar basılırsa kök dizine dön
      _navigatorKeys[index].currentState?.popUntil((route) => route.isFirst);
    } else {
      setState(() => _selectedTab = index);
    }
  }

  // Geri butonuna basıldığında iç navigasyonu kontrol et
  Future<bool> _onWillPop() async {
    final isFirstRouteInCurrentTab = !await _navigatorKeys[_selectedTab].currentState!.maybePop();
    if (isFirstRouteInCurrentTab) {
      if (_selectedTab != 0) {
        setState(() => _selectedTab = 0);
        return false;
      }
    }
    return isFirstRouteInCurrentTab;
  }

  @override
  Widget build(BuildContext context) {
    // ignore: deprecated_member_use
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: IndexedStack(
          index: _selectedTab,
          children: [
            _buildTabNavigator(0, const DashboardView()),
            _buildTabNavigator(1, const PortfolioScreen()),
            _buildTabNavigator(2, const FinanceScreen()),
            _buildTabNavigator(3, const MarketScreen()),
            _buildTabNavigator(4, const ToolsScreen()),
          ],
        ),
        bottomNavigationBar: _buildBottomNav(),
      ),
    );
  }

  Widget _buildTabNavigator(int index, Widget rootPage) {
    return Navigator(
      key: _navigatorKeys[index],
      onGenerateRoute: (routeSettings) {
        return MaterialPageRoute(
          builder: (context) => rootPage,
        );
      },
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surfaceDark,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryColor.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                  0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Ozet'),
              _buildNavItem(1, Icons.pie_chart_outline_rounded,
                  Icons.pie_chart_rounded, 'Portfolyo'),
              _buildNavItem(2, Icons.account_balance_wallet_outlined,
                  Icons.account_balance_wallet_rounded, 'Finans'),
              _buildNavItem(3, Icons.candlestick_chart_outlined,
                  Icons.candlestick_chart_rounded, 'Piyasa'),
              _buildNavItem(
                  4, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Araclar'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
      int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _selectedTab == index;
    return GestureDetector(
      onTap: () => _onTabTapped(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryColor.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? iconFilled : iconOutlined,
              color: isSelected ? AppTheme.primaryColor : AppTheme.textDim,
              size: 24,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? AppTheme.primaryColor : AppTheme.textDim,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
