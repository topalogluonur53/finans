import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:finans_app/data/providers/auth_provider.dart';
import 'package:finans_app/presentation/screens/banks/banks_screen.dart';
import 'package:finans_app/presentation/screens/debts/receivables_screen.dart';
import 'package:finans_app/presentation/screens/debts/debts_screen.dart';
import 'package:finans_app/presentation/screens/settings/settings_screen.dart';

// ─── Renk sabitleri (login ile aynı palet) ───────────────────────────────────
const _kBlueDark = Color(0xFF002F6C);
const _kBlueMid  = Color(0xFF0057B8);
const _kBg       = Color(0xFFF0F4FA);
const _kText     = Color(0xFF1A1A2E);
const _kSubText  = Color(0xFF6B7280);

class MainDrawer extends StatelessWidget {
  const MainDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = Provider.of<AuthProvider>(context);

    final firstName = auth.user?.firstName ?? '';
    final lastName  = auth.user?.lastName  ?? '';
    final fullName  = '${firstName.trim()} ${lastName.trim()}'.trim();
    final displayName = fullName.isNotEmpty ? fullName : (auth.username ?? 'Kullanıcı');
    final email = auth.user?.email ?? '';

    // Baş harfler avatar için
    final initials = () {
      final parts = displayName.trim().split(' ').where((p) => p.isNotEmpty).toList();
      if (parts.length >= 2) return '${parts.first[0]}${parts.last[0]}'.toUpperCase();
      if (parts.isNotEmpty) return parts.first[0].toUpperCase();
      return 'U';
    }();

    return Drawer(
      backgroundColor: _kBg,
      child: Column(
        children: [
          // ── Header – lacivert bant ────────────────────────────────────────
          _DrawerHeader(
            displayName: displayName,
            email: email,
            initials: initials,
          ),

          // ── Menü öğeleri ─────────────────────────────────────────────────
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              children: [
                const _SectionLabel(label: 'FİNANSAL'),
                _DrawerTile(
                  icon: Icons.account_balance_outlined,
                  color: _kBlueMid,
                  title: 'Bankalar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const BanksScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.call_received_outlined,
                  color: Colors.green.shade600,
                  title: 'Alacak',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const ReceivablesScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.call_made_outlined,
                  color: Colors.orange.shade700,
                  title: 'Verecek',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const DebtsScreen()),
                    );
                  },
                ),

                const SizedBox(height: 8),
                Divider(color: Colors.grey.shade200, height: 1),
                const SizedBox(height: 8),

                const _SectionLabel(label: 'GENEL'),
                _DrawerTile(
                  icon: Icons.settings_outlined,
                  color: _kSubText,
                  title: 'Ayarlar',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const SettingsScreen()),
                    );
                  },
                ),
                _DrawerTile(
                  icon: Icons.share_outlined,
                  color: _kSubText,
                  title: 'Uygulamayı Paylaş',
                  onTap: () {
                    Navigator.pop(context);
                    Share.share('FinansApp uygulamasını deneyin!');
                  },
                ),
              ],
            ),
          ),

          // ── Çıkış butonu ─────────────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: Colors.grey.shade200)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.red.shade50,
                    foregroundColor: Colors.red.shade600,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                  ),
                  icon: Icon(Icons.logout, color: Colors.red.shade600),
                  label: Text(
                    'Çıkış Yap',
                    style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: Colors.red.shade600),
                  ),
                  onPressed: () => auth.logout(),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Header ────────────────────────────────────────────────────────────────────
class _DrawerHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String initials;

  const _DrawerHeader({
    required this.displayName,
    required this.email,
    required this.initials,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: _kBlueDark,
      padding: EdgeInsets.fromLTRB(
        20,
        MediaQuery.of(context).padding.top + 20,
        20,
        24,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo satırı
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'O',
                  style: TextStyle(
                    color: _kBlueDark,
                    fontSize: 22,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FinansApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'Kişisel Finans Yönetimi',
                    style: TextStyle(
                      color: Colors.white60,
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Avatar + Kullanıcı bilgisi
          Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (email.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        email,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Bölüm Başlığı ─────────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String label;
  const _SectionLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 12, top: 12, bottom: 6),
      child: Text(
        label,
        style: const TextStyle(
          color: _kSubText,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

// ─── Menü Maddesi ───────────────────────────────────────────────────────────────
class _DrawerTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final VoidCallback onTap;

  const _DrawerTile({
    required this.icon,
    required this.color,
    required this.title,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: _kText,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
