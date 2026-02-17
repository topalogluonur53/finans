import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/providers/auth_provider.dart';
import 'package:finans_app/presentation/screens/portfolio/portfolio_screen.dart';
import 'package:finans_app/presentation/screens/finance/finance_screen.dart';
import 'package:finans_app/presentation/screens/market/market_screen.dart';
import 'package:finans_app/presentation/screens/tools/tools_screen.dart';
import 'package:finans_app/presentation/screens/settings/settings_screen.dart';
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
    const MarketScreen(),
    const ToolsScreen(),
  ];

  void _shareApp() {
    Share.share(
      'Finans App ile finansal durumunuzu takip edin! Portföy yönetimi, gelir-gider takibi ve daha fazlası...',
      subject: 'Finans App',
    );
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        backgroundColor: AppTheme.surfaceDark,
        elevation: 0,
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.backgroundDark,
        child: Column(
          children: [
            // Premium User Header
            Container(
              padding: const EdgeInsets.only(top: 50, bottom: 20, left: 20, right: 20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppTheme.primaryColor.withOpacity(0.8), AppTheme.secondaryColor.withOpacity(0.8)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(30),
                  bottomRight: Radius.circular(30),
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.white,
                    child: Text(
                      (authProvider.username ?? 'K').substring(0, 1).toUpperCase(),
                      style: const TextStyle(
                        fontSize: 30,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.primaryColor,
                      ),
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          authProvider.username ?? 'Kullanıcı',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          authProvider.email ?? '',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.white.withOpacity(0.8),
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Menu Items with custom styling
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                children: [
                  _buildDrawerTile(
                    icon: Icons.person_outline,
                    title: 'Kullanıcı Bilgileri',
                    onTap: () {
                      Navigator.pop(context);
                      _showUserInfoDialog(context, authProvider);
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.settings_outlined,
                    title: 'Ayarlar',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  _buildDrawerTile(
                    icon: Icons.share_outlined,
                    title: 'Uygulamayı Paylaş',
                    onTap: () {
                      Navigator.pop(context);
                      _shareApp();
                    },
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    child: Divider(color: AppTheme.surfaceDark, thickness: 1),
                  ),
                  _buildDrawerTile(
                    icon: Icons.help_outline,
                    title: 'Yardım & Destek',
                    onTap: () {
                      Navigator.pop(context);
                      // Destek aksiyonu
                    },
                  ),
                ],
              ),
            ),
            
            // Logout Button at the bottom
            Padding(
              padding: const EdgeInsets.all(20),
              child: ListTile(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
                tileColor: AppTheme.errorColor.withOpacity(0.1),
                leading: const Icon(Icons.logout, color: AppTheme.errorColor),
                title: const Text(
                  'Çıkış Yap',
                  style: TextStyle(color: AppTheme.errorColor, fontWeight: FontWeight.bold),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _showLogoutDialog(context, authProvider);
                },
              ),
            ),
          ],
        ),
      ),

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
          BottomNavigationBarItem(icon: Icon(Icons.show_chart), label: 'Piyasa'),
          BottomNavigationBarItem(icon: Icon(Icons.build), label: 'Araçlar'),
        ],
      ),
    );
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Özet';
      case 1:
        return 'Portföy';
      case 2:
        return 'Finans';
      case 3:
        return 'Piyasa';
      case 4:
        return 'Araçlar';
      default:
        return 'Finans App';
    }
  }

  void _showUserInfoDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(Icons.person, color: AppTheme.primaryColor),
            const SizedBox(width: 10),
            const Text(
              'Profil Detayları',
              style: TextStyle(color: AppTheme.textLight),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryColor.withOpacity(0.2),
                child: Text(
                  (authProvider.username ?? 'K').substring(0, 1).toUpperCase(),
                  style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Kullanıcı Adı', authProvider.username ?? '-'),
            const Divider(color: AppTheme.textDim, height: 20),
            _buildInfoRow('Ad Soyad', '${authProvider.user?.firstName ?? ''} ${authProvider.user?.lastName ?? ''}'.trim().isEmpty ? '-' : '${authProvider.user?.firstName} ${authProvider.user?.lastName}'),
            const Divider(color: AppTheme.textDim, height: 20),
            _buildInfoRow('E-posta', authProvider.email ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat', style: TextStyle(color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }


  Widget _buildInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: AppTheme.textDim,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: AppTheme.textLight,
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildDrawerTile({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontWeight: FontWeight.w500,
        ),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textDim, size: 20),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      hoverColor: AppTheme.primaryColor.withOpacity(0.1),
    );
  }

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Çıkış Yap',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: const Text(
          'Çıkış yapmak istediğinizden emin misiniz?',
          style: TextStyle(color: AppTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}
