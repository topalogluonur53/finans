import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:http/http.dart' as http;
import 'package:finans_app/core/theme/app_theme.dart';
import 'package:finans_app/core/constants/api_constants.dart';
import 'package:finans_app/data/providers/auth_provider.dart';

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
      backgroundColor: AppTheme.backgroundDark,
      appBar: AppBar(
        title: const Text('Ayarlar'),
        elevation: 0,
        backgroundColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
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
                  title: 'Şifre Değiştir',
                  subtitle: 'Hesap şifrenizi güncelleyin',
                  onTap: () => _showChangePasswordSheet(),
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
            const SizedBox(height: 80), // alt bar boşluk payı
          ],
        ),
      ),
    );
  }

  // ─── Builders ──────────────────────────────────────────────────────────────

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
      title: Text(title, style: const TextStyle(color: AppTheme.textLight)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
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
      title: Text(title, style: const TextStyle(color: AppTheme.textLight)),
      subtitle: Text(subtitle,
          style: const TextStyle(color: AppTheme.textDim, fontSize: 12)),
      trailing:
          const Icon(Icons.chevron_right, color: AppTheme.textDim),
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
      title: Text(title, style: const TextStyle(color: AppTheme.textLight)),
      trailing: DropdownButton<String>(
        value: value,
        dropdownColor: AppTheme.surfaceDark,
        style: const TextStyle(color: AppTheme.textLight),
        underline: Container(),
        items: items.map((item) {
          return DropdownMenuItem(value: item, child: Text(item));
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  // Şifre Değiştirme – Bottom Sheet (NumPad uyumlu)
  // ═══════════════════════════════════════════════════════════════════════════

  void _showChangePasswordSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const _ChangePasswordSheet(),
    );
  }

  // ─── Diğer dialoglar ───────────────────────────────────────────────────────

  void _showAboutDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surfaceDark,
        title: const Text('Finans App',
            style: TextStyle(color: AppTheme.textLight)),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Versiyon: 1.0.0',
                style: TextStyle(color: AppTheme.textDim)),
            SizedBox(height: 16),
            Text(
              'Finans App ile finansal durumunuzu kolayca takip edin. Portföy yönetimi, gelir-gider takibi, piyasa verileri ve daha fazlası...',
              style: TextStyle(color: AppTheme.textLight),
            ),
            SizedBox(height: 16),
            Text('© 2026 Finans App. Tüm hakları saklıdır.',
                style: TextStyle(color: AppTheme.textDim, fontSize: 12)),
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
        title: const Text('Bize Ulaşın',
            style: TextStyle(color: AppTheme.textLight)),
        content: TextField(
          controller: messageController,
          maxLines: 4,
          style: const TextStyle(color: AppTheme.textLight),
          decoration: const InputDecoration(
            hintText: 'Mesajınızı veya önerinizi yazın...',
            hintStyle: TextStyle(color: AppTheme.textDim),
            border: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor)),
            focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppTheme.primaryColor)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('İptal',
                style: TextStyle(color: AppTheme.textDim)),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              if (messageController.text.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content:
                        Text('Mesajınız başarıyla iletildi. Teşekkür ederiz!'),
                    backgroundColor: Colors.green,
                  ),
                );
              }
            },
            child: const Text('Gönder',
                style: TextStyle(color: AppTheme.primaryColor)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
// Şifre Değiştirme Bottom Sheet – gerçek API ile
// ═══════════════════════════════════════════════════════════════════════════════
class _ChangePasswordSheet extends StatefulWidget {
  const _ChangePasswordSheet();

  @override
  State<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends State<_ChangePasswordSheet> {
  final _formKey = GlobalKey<FormState>();
  final _currentCtrl  = TextEditingController();
  final _newCtrl      = TextEditingController();
  final _confirmCtrl  = TextEditingController();

  bool _showCurrent = false;
  bool _showNew     = false;
  bool _showConfirm = false;
  bool _loading     = false;
  String? _errorMsg;

  @override
  void dispose() {
    _currentCtrl.dispose();
    _newCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  // ─── API İsteği ────────────────────────────────────────────────────────────
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _errorMsg = null; });

    final token = context.read<AuthProvider>().token;

    // Demo modda API yoktur
    if (token == 'offline_demo_token') {
      await Future.delayed(const Duration(milliseconds: 600));
      if (!mounted) return;
      setState(() => _loading = false);
      _showSuccess('Demo modda şifre değiştirilemez.');
      return;
    }

    try {
      final url = Uri.parse(
          '${ApiConstants.baseUrl}${ApiConstants.changePasswordEndpoint}');
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'current_password': _currentCtrl.text,
          'new_password': _newCtrl.text,
        }),
      ).timeout(const Duration(seconds: 15));

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(children: [
              Icon(Icons.check_circle_outline, color: Colors.white),
              SizedBox(width: 10),
              Text('Şifreniz başarıyla değiştirildi.'),
            ]),
            backgroundColor: Color(0xFF2E7D32),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(12))),
          ),
        );
      } else {
        final body = jsonDecode(response.body);
        setState(() {
          _loading  = false;
          _errorMsg = body['error'] ?? 'Bir hata oluştu.';
        });
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading  = false;
        _errorMsg = 'Sunucuya ulaşılamıyor.\nİnternet bağlantınızı kontrol edin.';
      });
    }
  }

  void _showSuccess(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.orange),
    );
  }

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    return Container(
      padding: EdgeInsets.only(
        left: 24, right: 24, top: 24,
        bottom: mq.viewInsets.bottom + 32,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF1C2138),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Handle çizgisi ──────────────────────────────────────────
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // ── Başlık ──────────────────────────────────────────────────
              Row(
                children: [
                  Container(
                    width: 44, height: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.lock_reset_rounded,
                        color: AppTheme.primaryColor, size: 24),
                  ),
                  const SizedBox(width: 14),
                  const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Şifre Değiştir',
                          style: TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                      SizedBox(height: 2),
                      Text('Hesap güvenliğinizi güncel tutun',
                          style: TextStyle(color: Colors.white54, fontSize: 12)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // ── Hata mesajı ─────────────────────────────────────────────
              if (_errorMsg != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline_rounded,
                          color: Colors.redAccent, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(_errorMsg!,
                            style: const TextStyle(
                                color: Colors.redAccent, fontSize: 13)),
                      ),
                    ],
                  ),
                ),
              ],

              // ── Mevcut Şifre ────────────────────────────────────────────
              _buildField(
                controller: _currentCtrl,
                label: 'Mevcut Şifre',
                hint: 'Mevcut şifrenizi girin',
                obscure: !_showCurrent,
                toggleObscure: () =>
                    setState(() => _showCurrent = !_showCurrent),
                validator: (v) =>
                    (v == null || v.isEmpty) ? 'Bu alan zorunludur' : null,
              ),
              const SizedBox(height: 16),

              // ── Yeni Şifre ──────────────────────────────────────────────
              _buildField(
                controller: _newCtrl,
                label: 'Yeni Şifre',
                hint: 'En az 4 karakter',
                obscure: !_showNew,
                toggleObscure: () =>
                    setState(() => _showNew = !_showNew),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Bu alan zorunludur';
                  if (v.length < 4) return 'En az 4 karakter olmalıdır';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // ── Yeni Şifre Tekrar ───────────────────────────────────────
              _buildField(
                controller: _confirmCtrl,
                label: 'Yeni Şifre (Tekrar)',
                hint: 'Yeni şifrenizi tekrar girin',
                obscure: !_showConfirm,
                toggleObscure: () =>
                    setState(() => _showConfirm = !_showConfirm),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Bu alan zorunludur';
                  if (v != _newCtrl.text) return 'Şifreler uyuşmuyor';
                  return null;
                },
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _submit(),
              ),
              const SizedBox(height: 28),

              // ── Butonlar ────────────────────────────────────────────────
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _loading ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white54,
                        side: const BorderSide(color: Colors.white24),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('İptal'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryColor,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            AppTheme.primaryColor.withValues(alpha: 0.4),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2.5),
                            )
                          : const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.check_rounded, size: 20),
                                SizedBox(width: 8),
                                Text('Değiştir',
                                    style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 15)),
                              ],
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required bool obscure,
    required VoidCallback toggleObscure,
    required String? Function(String?) validator,
    TextInputAction textInputAction = TextInputAction.next,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                color: Colors.white70,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          textInputAction: textInputAction,
          onFieldSubmitted: onFieldSubmitted,
          style: const TextStyle(color: Colors.white),
          validator: validator,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(color: Colors.white30, fontSize: 14),
            filled: true,
            fillColor: Colors.white.withValues(alpha: 0.07),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.white12),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: AppTheme.primaryColor, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.redAccent, width: 1.5),
            ),
            suffixIcon: IconButton(
              icon: Icon(
                obscure
                    ? Icons.visibility_off_outlined
                    : Icons.visibility_outlined,
                color: Colors.white38,
                size: 20,
              ),
              onPressed: toggleObscure,
            ),
          ),
        ),
      ],
    );
  }
}
