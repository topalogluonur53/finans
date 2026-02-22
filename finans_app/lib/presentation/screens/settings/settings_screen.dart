import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = true;
  bool _darkModeEnabled = true;
  bool _biometricEnabled = false;
  String _currency = 'TRY';
  String _language = 'TR';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              AppTheme.backgroundDark,
              AppTheme.surfaceDark.withValues(alpha: 0.5)
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.symmetric(vertical: 20),
          children: [
            _buildSettingsCard(
              title: 'Genel Yapılandırma',
              children: [
                _buildSwitchTile(
                  icon: Icons.notifications_active_outlined,
                  title: 'Bildirimler',
                  subtitle: 'Fiyat uyarıları ve haberler',
                  value: _notificationsEnabled,
                  onChanged: (value) =>
                      setState(() => _notificationsEnabled = value),
                ),
                _buildSwitchTile(
                  icon: Icons.dark_mode_outlined,
                  title: 'Karanlık Mod',
                  subtitle: 'Gözlerinizi dinlendirin',
                  value: _darkModeEnabled,
                  onChanged: (value) =>
                      setState(() => _darkModeEnabled = value),
                ),
              ],
            ),
            _buildSettingsCard(
              title: 'Güvenlik & Gizlilik',
              children: [
                _buildSwitchTile(
                  icon: Icons.fingerprint,
                  title: 'Biyometrik Giriş',
                  subtitle: 'Hızlı ve güvenli erişim',
                  value: _biometricEnabled,
                  onChanged: (value) =>
                      setState(() => _biometricEnabled = value),
                ),
                _buildNavigationTile(
                  icon: Icons.lock_outline,
                  title: 'Şifre İşlemleri',
                  subtitle: 'Güvenliğinizi güncel tutun',
                  onTap: () => _showChangePasswordDialog(),
                ),
              ],
            ),
            _buildSettingsCard(
              title: 'Bölgesel Ayarlar',
              children: [
                _buildDropdownTile(
                  icon: Icons.currency_exchange,
                  title: 'Varsayılan Para Birimi',
                  value: _currency,
                  items: const ['TRY', 'USD', 'EUR', 'GBP'],
                  onChanged: (value) => setState(() => _currency = value!),
                ),
                _buildDropdownTile(
                  icon: Icons.translate,
                  title: 'Uygulama Dili',
                  value: _language,
                  items: const ['TR', 'EN'],
                  onChanged: (value) => setState(() => _language = value!),
                ),
              ],
            ),
            _buildSettingsCard(
              title: 'Destek & Hakkında',
              children: [
                _buildNavigationTile(
                  icon: Icons.info_outline,
                  title: 'Uygulama Sürümü',
                  subtitle: 'v1.0.0 (Beta)',
                  onTap: () => _showAboutDialog(),
                ),
                _buildNavigationTile(
                  icon: Icons.contact_support_outlined,
                  title: 'Bize Ulaşın',
                  subtitle: 'Sorun bildirin veya öneri sunun',
                  onTap: () => _showContactSupportDialog(),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ElevatedButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Ayarlar kaydedildi')),
                  );
                },
                child: const Text('Ayarları Kaydet'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSettingsCard(
      {required String title, required List<Widget> children}) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Text(
              title,
              style: const TextStyle(
                color: AppTheme.primaryColor,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          ...children,
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textLight),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
      ),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeThumbColor: AppTheme.primaryColor,
      ),
    );
  }

  Widget _buildNavigationTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textLight),
      ),
      subtitle: Text(
        subtitle,
        style: const TextStyle(color: AppTheme.textDim, fontSize: 12),
      ),
      trailing: const Icon(Icons.chevron_right, color: AppTheme.textDim),
      onTap: onTap,
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: AppTheme.primaryColor),
      title: Text(
        title,
        style: const TextStyle(color: AppTheme.textLight),
      ),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppTheme.surfaceDark,
        style: const TextStyle(color: AppTheme.textLight),
        underline: Container(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  void _showChangePasswordDialog() {
    final currentPasswordController = TextEditingController();
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Şifre Değiştir',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: currentPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Mevcut Şifre',
                prefixIcon: Icon(Icons.lock_outline),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: confirmPasswordController,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Yeni Şifre (Tekrar)',
                prefixIcon: Icon(Icons.lock),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('İptal', style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              if (newPasswordController.text.isNotEmpty &&
                  newPasswordController.text == confirmPasswordController.text) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifreniz başarıyla güncellendi'),
                    backgroundColor: Colors.green,
                  ),
                );
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Şifreler uyuşmuyor veya boş!'),
                    backgroundColor: AppTheme.errorColor,
                  ),
                );
              }
            },
            child: const Text('Değiştir',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Finans App',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Versiyon: 1.0.0',
              style: TextStyle(color: AppTheme.textDim),
            ),
            SizedBox(height: 16),
            Text(
              'Finans App ile finansal durumunuzu kolayca takip edin. Portföy yönetimi, gelir-gider takibi, piyasa verileri ve daha fazlası...',
              style: TextStyle(color: AppTheme.textLight),
            ),
            SizedBox(height: 16),
            Text(
              '© 2026 Finans App. Tüm hakları saklıdır.',
              style: TextStyle(color: AppTheme.textDim, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Kapat',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }

  void _showContactSupportDialog() {
    final messageController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text(
          'Bize Ulaşın',
          style: TextStyle(color: AppTheme.textLight),
        ),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: const InputDecoration(
            hintText: 'Mesajınızı veya önerinizi yazın...',
            hintStyle: TextStyle(color: AppTheme.textDim),
            border: OutlineInputBorder(
               borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
            focusedBorder: OutlineInputBorder(
               borderSide: BorderSide(color: AppTheme.primaryColor),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal', style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (messageController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Mesajınız başarıyla iletildi. Teşekkür ederiz!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Gönder', style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}
