import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/data/providers/auth_provider.dart';
import 'package:finans_app/presentation/screens/portfolio/portfolio_screen.dart';
import 'package:finans_app/presentation/screens/finance/finance_screen.dart';
import 'package:finans_app/presentation/screens/market/market_screen.dart';
import 'package:finans_app/presentation/screens/tools/tools_screen.dart';
import 'package:finans_app/data/providers/portfolio_provider.dart';
import 'package:finans_app/data/providers/finance_provider.dart';
import 'package:finans_app/presentation/screens/portfolio/add_asset_screen.dart';
import 'package:finans_app/presentation/screens/finance/add_transaction_screen.dart';
import 'package:finans_app/presentation/screens/banks/banks_screen.dart';
import 'package:finans_app/presentation/screens/debts/receivables_screen.dart';
import 'package:finans_app/presentation/screens/debts/debts_screen.dart';
import 'dashboard_view.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  int _currentIndex = 0;

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

  Future<void> _shareApp() async {
    const appName = 'Finans App';
    const playStoreUrl =
        'https://play.google.com/store/apps/details?id=com.finans.finans_app';
    const appStoreUrl =
        'https://apps.apple.com/app/finans-app/id000000000'; // App Store'a yüklenince güncelleyin

    final message = '''$appName ile finansal durumunuzu kolayca takip edin! 💰

✅ Portföy yönetimi
✅ Gelir-gider takibi
✅ Piyasa verileri
✅ Halka arz bilgileri

📱 Android: $playStoreUrl
🍎 iOS: $appStoreUrl''';

    try {
      // assets'teki ikonu temp klasörüne kopyala
      final byteData =
          await rootBundle.load('assets/icons/app_icon.png');
      final tempDir = await getTemporaryDirectory();
      final iconFile = File('${tempDir.path}/finans_app_icon.png');
      await iconFile.writeAsBytes(byteData.buffer.asUint8List());

      await Share.shareXFiles(
        [XFile(iconFile.path, mimeType: 'image/png')],
        text: message,
        subject: appName,
      );
    } catch (_) {
      // İkon paylaşılamazsa sadece metin gönder
      Share.share(message, subject: appName);
    }
  }

  @override
  Widget build(BuildContext context) {
    final screens = _screens;
    final authProvider = Provider.of<AuthProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(_getTitle()),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              if (_currentIndex == 0) {
                Provider.of<PortfolioProvider>(context, listen: false)
                    .fetchAssets();
                Provider.of<FinanceProvider>(context, listen: false)
                    .fetchData();
              } else if (_currentIndex == 1) {
                Provider.of<PortfolioProvider>(context, listen: false)
                    .fetchAssets();
              } else if (_currentIndex == 2) {
                Provider.of<FinanceProvider>(context, listen: false)
                    .fetchData();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.notifications_none),
            onPressed: () {},
          ),
        ],
      ),
      drawer: Drawer(
        backgroundColor: AppTheme.backgroundDark,
        child: Column(
          children: [
            // ── Premium User Header ──────────────────────────────────
            _DrawerHeader(authProvider: authProvider),

            // ── Navigation Menu ─────────────────────────────────────
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                children: [
                  // Section label
                  _SectionLabel(label: 'Finansal'),
                  _MinimalTile(
                    icon: Icons.account_balance_outlined,
                    title: 'Bankalar',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const BanksScreen()));
                    },
                  ),
                  _MinimalTile(
                    icon: Icons.call_received_outlined,
                    title: 'Alacak',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const ReceivablesScreen()));
                    },
                  ),
                  _MinimalTile(
                    icon: Icons.call_made_outlined,
                    title: 'Verecek',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context,
                          MaterialPageRoute(builder: (_) => const DebtsScreen()));
                    },
                  ),

                  const SizedBox(height: 8),
                  Divider(color: AppTheme.textDim.withOpacity(0.18), height: 1),
                  const SizedBox(height: 8),

                  // Section label
                  _SectionLabel(label: 'Genel'),
                  _MinimalTile(
                    icon: Icons.share_outlined,
                    title: 'Uygulamayi Paylas',
                    onTap: () {
                      Navigator.pop(context);
                      _shareApp();
                    },
                  ),
                ],
              ),
            ),

            // ── Bottom: Profile & Settings & Logout ─────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: AppTheme.textDim.withOpacity(0.18),
                    width: 1,
                  ),
                ),
              ),
              child: Column(
                children: [
                  _MinimalTile(
                    icon: Icons.person_outline_rounded,
                    title: 'Kullanici Bilgileri',
                    onTap: () {
                      Navigator.pop(context);
                      _showUserInfoDialog(context, authProvider);
                    },
                  ),
                  _MinimalTile(
                    icon: Icons.settings_outlined,
                    title: 'Ayarlar',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.pushNamed(context, '/settings');
                    },
                  ),
                  const SizedBox(height: 4),
                  // Logout
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16, top: 4),
                    child: SizedBox(
                      width: double.infinity,
                      child: TextButton.icon(
                        style: TextButton.styleFrom(
                          backgroundColor: AppTheme.errorColor.withValues(alpha: 0.1),
                          foregroundColor: AppTheme.errorColor,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        icon: const Icon(Icons.logout_rounded, size: 20),
                        label: const Text(
                          'Cikis Yap',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
                        onPressed: () {
                          Navigator.pop(context);
                          _showLogoutDialog(context, authProvider);
                        },
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: screens[_currentIndex],
      floatingActionButton: _buildFab(),
      bottomNavigationBar: Container(
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
                _buildNavItem(0, Icons.dashboard_outlined, Icons.dashboard_rounded, 'Ozet'),
                _buildNavItem(1, Icons.pie_chart_outline_rounded, Icons.pie_chart_rounded, 'Portfolyo'),
                _buildNavItem(2, Icons.account_balance_wallet_outlined, Icons.account_balance_wallet_rounded, 'Finans'),
                _buildNavItem(3, Icons.candlestick_chart_outlined, Icons.candlestick_chart_rounded, 'Piyasa'),
                _buildNavItem(4, Icons.grid_view_outlined, Icons.grid_view_rounded, 'Araclar'),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int index, IconData iconOutlined, IconData iconFilled, String label) {
    final isSelected = _currentIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _currentIndex = index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryColor.withValues(alpha: 0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              transitionBuilder: (child, anim) => ScaleTransition(scale: anim, child: child),
              child: Icon(
                isSelected ? iconFilled : iconOutlined,
                key: ValueKey(isSelected),
                color: isSelected ? AppTheme.primaryColor : AppTheme.textDim,
                size: 24,
              ),
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

  Widget? _buildFab() {
    switch (_currentIndex) {
      case 1: // Portfolio
        return FloatingActionButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => const AddAssetScreen()),
            );
          },
          child: const Icon(Icons.add),
        );
      case 2: // Finance
        return FloatingActionButton(
          onPressed: () {
            showModalBottomSheet(
              context: context,
              builder: (context) => const TransactionTypeDialog(),
            );
          },
          child: const Icon(Icons.add),
        );
      default:
        return null;
    }
  }

  String _getTitle() {
    switch (_currentIndex) {
      case 0:
        return 'Ozet';
      case 1:
        return 'Portfolyo';
      case 2:
        return 'Finans';
      case 3:
        return 'Piyasa';
      case 4:
        return 'Araclar';
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
        title: const Row(
          children: [
            Icon(Icons.person, color: AppTheme.primaryColor),
            SizedBox(width: 10),
            Text(
              'Profil Detaylari',
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
                backgroundColor: AppTheme.primaryColor.withValues(alpha: 0.2),
                child: Text(
                  (authProvider.username ?? 'K').substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryColor),
                ),
              ),
            ),
            const SizedBox(height: 20),
            _buildInfoRow('Kullanici Adi', authProvider.username ?? '-'),
            const Divider(color: AppTheme.textDim, height: 20),
            _buildInfoRow(
                'Ad Soyad',
                '${authProvider.user?.firstName ?? ''} ${authProvider.user?.lastName ?? ''}'
                        .trim()
                        .isEmpty
                    ? '-'
                    : '${authProvider.user?.firstName} ${authProvider.user?.lastName}'),
            const Divider(color: AppTheme.textDim, height: 20),
            _buildInfoRow('E-posta', authProvider.email ?? '-'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat',
                style: TextStyle(
                    color: AppTheme.primaryColor, fontWeight: FontWeight.bold)),
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

  void _showLogoutDialog(BuildContext context, AuthProvider authProvider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Cikis Yap',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: const Text(
          'Cikis yapmak istediginizden emin misiniz?',
          style: TextStyle(color: AppTheme.textDim),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Iptal', style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              authProvider.logout();
              Navigator.pop(context);
            },
            child: const Text('Cikis Yap',
                style: TextStyle(color: AppTheme.errorColor)),
          ),
        ],
      ),
    );
  }
}

// ── Drawer Header Widget ──────────────────────────────────────────────────────

class _DrawerHeader extends StatelessWidget {
  final AuthProvider authProvider;
  const _DrawerHeader({required this.authProvider});

  @override
  Widget build(BuildContext context) {
    final firstName = authProvider.user?.firstName?.trim() ?? '';
    final lastName = authProvider.user?.lastName?.trim() ?? '';
    final fullName = '$firstName $lastName'.trim();
    final hasFullName = fullName.isNotEmpty;
    final displayName = hasFullName ? fullName : (authProvider.username ?? 'Kullanici');
    final initial = displayName.isNotEmpty ? displayName.substring(0, 1).toUpperCase() : 'K';
    final subtitle = hasFullName
        ? (authProvider.username ?? authProvider.email ?? '')
        : (authProvider.email ?? '');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 56, bottom: 24, left: 20, right: 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF003380), Color(0xFF001A4D)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
                width: 2.5,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 30,
              backgroundColor: Colors.white,
              child: Text(
                initial,
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF003380),
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          // Name & subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                    letterSpacing: 0.2,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                if (subtitle.isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.65),
                      letterSpacing: 0.2,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Section Label ─────────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 12, 8, 4),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppTheme.primaryColor.withOpacity(0.65),
          letterSpacing: 1.4,
        ),
      ),
    );
  }
}

// ── Minimal Drawer Tile ────────────────────────────────────────────────────────

class _MinimalTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final VoidCallback onTap;

  const _MinimalTile({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      leading: Icon(icon, color: AppTheme.primaryColor, size: 24),
      title: Text(
        title,
        style: const TextStyle(
          color: AppTheme.textLight,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: onTap,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      hoverColor: AppTheme.primaryColor.withValues(alpha: 0.08),
      splashColor: AppTheme.primaryColor.withValues(alpha: 0.12),
    );
  }
}

// ── Transaction Type Dialog ───────────────────────────────────────────────────

class TransactionTypeDialog extends StatelessWidget {
  const TransactionTypeDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
      decoration: const BoxDecoration(
        color: AppTheme.surfaceDark,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Islem Turu Secin',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _TypeButton(
                icon: Icons.arrow_upward,
                color: Colors.green,
                label: 'Gelir Ekle',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(
                          type: TransactionType.income),
                    ),
                  );
                },
              ),
              _TypeButton(
                icon: Icons.arrow_downward,
                color: Colors.red,
                label: 'Gider Ekle',
                onTap: () {
                  Navigator.pop(context);
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const AddTransactionScreen(
                          type: TransactionType.expense),
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 20),
        ],
      ),
    );
  }
}

class _TypeButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final VoidCallback onTap;

  const _TypeButton({
    required this.icon,
    required this.color,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.5)),
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 10),
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}