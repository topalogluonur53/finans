import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/auth_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Renk sabitleri – Login ekranındaki ile uyumlu
// ──────────────────────────────────────────────────────────────────────────────
const _kBlueDark = Color(0xFF002F6C);
const _kBlueMid  = Color(0xFF0057B8);
const _kBg       = Color(0xFFF0F4FA);
const _kCard     = Color(0xFFFFFFFF);
const _kText     = Color(0xFF1A1A2E);
const _kSubText  = Color(0xFF6B7280);

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  
  // ── Controllers ──
  final _nameController = TextEditingController(); // Ad Soyad
  final _phoneController = TextEditingController(); // Telefon/Kullanıcı Adı
  final _emailController = TextEditingController();
  final _pinController = TextEditingController();
  final _confirmPinController = TextEditingController();

  // ── Focus Nodes ──
  final _nameFocus = FocusNode();
  final _phoneFocus = FocusNode();
  final _emailFocus = FocusNode();
  final _pinFocus = FocusNode();
  final _confirmPinFocus = FocusNode();
  
  bool _obscurePin = true;
  bool _obscureConfirmPin = true;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _pinController.dispose();
    _confirmPinController.dispose();

    _nameFocus.dispose();
    _phoneFocus.dispose();
    _emailFocus.dispose();
    _pinFocus.dispose();
    _confirmPinFocus.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (_formKey.currentState!.validate()) {
      try {
        final nameParts = _nameController.text.trim().split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : '';
        final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';
        
        await Provider.of<AuthProvider>(context, listen: false).register(
          _phoneController.text.trim().replaceAll(' ', ''),
          _emailController.text.trim(),
          _pinController.text,
          firstName: firstName,
          lastName: lastName,
        );
        
        if (mounted) {
          _showSnack('Kayıt Başarıyla Tamamlandı!', isError: false);
          await Future.delayed(const Duration(seconds: 2));
          if (mounted) Navigator.pop(context);
        }
      } catch (e) {
        if (mounted) {
          _showSnack('❌ Hata: $e', isError: true);
        }
      }
    }
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFD32F2F) : Colors.green.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _kBlueDark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: Scaffold(
        backgroundColor: _kBg,
        body: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // Arka plan dalgası
              _BgWave(),

              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Kaydırılabilir Form
                    Expanded(
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.only(
                          left: 20, right: 20, top: 16, bottom: 32,
                        ),
                        physics: const ClampingScrollPhysics(),
                        child: _buildFormCard(isLoading),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _kBlueDark,
      padding: const EdgeInsets.fromLTRB(16, 12, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 22),
                onPressed: () => Navigator.pop(context),
              ),
              const Expanded(
                child: Text(
                  'Yeni Hesap Oluştur',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(width: 48), // Dengeleme için
            ],
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Aramıza Katılın',
              style: TextStyle(
                color: Colors.white,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Bilgilerinizi girerek saniyeler içinde kaydınızı tamamlayın.',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard(bool isLoading) {
    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kBlueDark.withOpacity(0.08),
            blurRadius: 24,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Ad Soyad
            _buildInputField(
              controller: _nameController,
              focusNode: _nameFocus,
              nextFocusNode: _phoneFocus,
              label: 'Ad Soyad',
              hint: 'Örn: Ahmet Yılmaz',
              icon: Icons.person_outline_rounded,
              keyboardType: TextInputType.name,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Ad Soyad gerekli';
                if (!val.trim().contains(' ')) return 'Lütfen Ad ve Soyad girin';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // Telefon No / Kullanıcı Adı
            _buildInputField(
              controller: _phoneController,
              focusNode: _phoneFocus,
              nextFocusNode: _emailFocus,
              label: 'Cep Telefonu No / Kullanıcı Adı',
              hint: 'Örn: 5XX XXX XX XX',
              icon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'Telefon no gerekli';
                final cleanVal = val.replaceAll(' ', '');
                if (cleanVal.length < 10) return 'Geçerli bir telefon girin';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // E-posta
            _buildInputField(
              controller: _emailController,
              focusNode: _emailFocus,
              nextFocusNode: _pinFocus,
              label: 'E-posta Adresi',
              hint: 'Örn: mail@ornek.com',
              icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress,
              validator: (val) {
                if (val == null || val.trim().isEmpty) return 'E-posta gerekli';
                if (!val.contains('@')) return 'Geçerli bir e-posta girin';
                return null;
              },
            ),
            const SizedBox(height: 20),

            // PIN Şifresi
            _buildInputField(
              controller: _pinController,
              focusNode: _pinFocus,
              nextFocusNode: _confirmPinFocus,
              label: '6 Haneli Şifre (PIN)',
              hint: '••••••',
              icon: Icons.dialpad_rounded,
              keyboardType: TextInputType.number,
              isPassword: true,
              obscureText: _obscurePin,
              maxLength: 6,
              onToggleVisibility: () => setState(() => _obscurePin = !_obscurePin),
              validator: (val) {
                if (val == null || val.isEmpty) return 'PIN gerekli';
                if (val.length < 6) return 'PIN tam 6 rakam olmalı';
                return null;
              },
              formatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 20),

            // PIN Onayı
            _buildInputField(
              controller: _confirmPinController,
              focusNode: _confirmPinFocus,
              label: 'Şifre Tekrar',
              hint: '••••••',
              icon: Icons.dialpad_rounded,
              keyboardType: TextInputType.number,
              isPassword: true,
              obscureText: _obscureConfirmPin,
              maxLength: 6,
              onToggleVisibility: () => setState(() => _obscureConfirmPin = !_obscureConfirmPin),
              validator: (val) {
                if (val == null || val.isEmpty) return 'Şifre tekrarı gerekli';
                if (val != _pinController.text) return 'Şifreler eşleşmiyor';
                return null;
              },
              formatters: [FilteringTextInputFormatter.digitsOnly],
              onFieldSubmitted: (_) => _register(),
            ),
            
            const SizedBox(height: 32),

            // Kayıt Butonu
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: isLoading ? null : _register,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _kBlueMid,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _kBlueMid.withOpacity(0.5),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 22, height: 22,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                      )
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Kayıt İşlemini Tamamla',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.3,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.check_circle_outline_rounded, size: 20),
                        ],
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Girişe Dön
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                style: TextButton.styleFrom(
                  foregroundColor: _kText,
                  textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                ),
                child: RichText(
                  text: const TextSpan(
                    text: 'Zaten hesabınız var mı? ',
                    style: TextStyle(color: _kSubText, fontSize: 14),
                    children: [
                      TextSpan(
                        text: 'Giriş Yapın',
                        style: TextStyle(color: _kBlueMid, fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    FocusNode? focusNode,
    FocusNode? nextFocusNode,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    bool isPassword = false,
    bool obscureText = false,
    int? maxLength,
    VoidCallback? onToggleVisibility,
    String? Function(String?)? validator,
    List<TextInputFormatter>? formatters,
    void Function(String)? onFieldSubmitted,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: _kBlueDark,
            letterSpacing: 0.3,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          focusNode: focusNode,
          keyboardType: keyboardType,
          textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
          onFieldSubmitted: onFieldSubmitted ?? (nextFocusNode != null ? (_) => FocusScope.of(context).requestFocus(nextFocusNode) : null),
          obscureText: obscureText,
          maxLength: maxLength,
          inputFormatters: formatters,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _kText,
            letterSpacing: 1,
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: _kSubText.withOpacity(0.4),
              fontWeight: FontWeight.w400,
              letterSpacing: 0,
            ),
            counterText: '',
            prefixIcon: Icon(icon, color: _kBlueMid.withOpacity(0.7), size: 22),
            suffixIcon: isPassword
                ? IconButton(
                    icon: Icon(
                      obscureText ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: _kSubText,
                      size: 20,
                    ),
                    onPressed: onToggleVisibility,
                  )
                : null,
            filled: true,
            fillColor: _kBg.withOpacity(0.5),
            contentPadding: const EdgeInsets.symmetric(vertical: 16),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: _kBlueMid, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: Colors.red, width: 1),
            ),
          ),
          validator: validator,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arka plan mavi dalga dekorasyonu (Login'deki ile aynı)
// ─────────────────────────────────────────────────────────────────────────────
class _BgWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0, right: 0, top: 0,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 220),
        painter: _WavePainter(),
      ),
    );
  }
}

class _WavePainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()..color = _kBlueDark;
    final path = Path()
      ..lineTo(0, size.height * 0.72)
      ..quadraticBezierTo(
        size.width * 0.25, size.height * 0.92,
        size.width * 0.5, size.height * 0.80,
      )
      ..quadraticBezierTo(
        size.width * 0.75, size.height * 0.68,
        size.width, size.height * 0.78,
      )
      ..lineTo(size.width, 0)
      ..close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter p) => false;
}
