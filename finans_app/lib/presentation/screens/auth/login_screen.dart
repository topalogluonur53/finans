import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:finans_app/data/providers/auth_provider.dart';

// ──────────────────────────────────────────────────────────────────────────────
// Renk sabitleri – İşBankası'nın mavi paleti
// ──────────────────────────────────────────────────────────────────────────────
const _kBlueDark = Color(0xFF002F6C);   // Koyu lacivert – header / logo
const _kBlueMid  = Color(0xFF0057B8);   // Orta mavi – butonlar / aktif bileşenler
const _kBg       = Color(0xFFF0F4FA);   // Ekran arka planı
const _kCard     = Color(0xFFFFFFFF);   // Kart arka planı
const _kText     = Color(0xFF1A1A2E);   // Ana metin
const _kSubText  = Color(0xFF6B7280);   // İkincil metin

// Hangi alan aktif olarak numpad bekliyor?
enum _ActiveField { none, username, password }

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {

  // ── Controllers ──────────────────────────────────────────────────────────
  final _usernameController = TextEditingController();
  final FocusNode _usernameFocusNode = FocusNode();
  final _passwordController = TextEditingController();
  final FocusNode _passwordFocusNode = FocusNode();
  final int _pinLength = 6;

  // ── NumPad state ──────────────────────────────────────────────────────────
  _ActiveField _activeField = _ActiveField.none;

  // ── Animasyon ─────────────────────────────────────────────────────────────
  late AnimationController _numPadAnim;
  late Animation<Offset>   _numPadSlide;

  // ── Beni hatırla ─────────────────────────────────────────────────────────
  bool _rememberMe = false;

  // ── Username alanı numpad ile mi girilecek? ───────────────────────────────
  // Kullanıcı adı sayısal (müşteri no / TCKN) ise numpad; değilse keyboard
  bool _usernameIsNumeric = true;
  bool _passwordIsNumeric = true;
  String? _actualUsername;

  bool get _isRememberedUser => _rememberMe && _actualUsername != null && _usernameController.text.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _numPadAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _numPadSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _numPadAnim, curve: Curves.easeOutCubic));

    _loadRememberMe();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _usernameFocusNode.dispose();
    _passwordController.dispose();
    _passwordFocusNode.dispose();
    _numPadAnim.dispose();
    super.dispose();
  }

  Future<void> _loadRememberMe() async {
    final prefs = await SharedPreferences.getInstance();
    final remember = prefs.getBool('remember_me') ?? false;
    final savedUser = prefs.getString('saved_username') ?? '';
    final savedDisplayName = prefs.getString('saved_display_name') ?? '';
    
    if (mounted) {
      setState(() {
        _rememberMe = remember;
        if (remember && savedUser.isNotEmpty) {
          _actualUsername = savedUser;
          _usernameController.text = savedDisplayName.isNotEmpty ? savedDisplayName : savedUser;
          _usernameIsNumeric = false;
          // Eğer kaydedilmiş bir kullanıcı varsa doğrudan şifre sormak için şifre alanını aç.
          Future.delayed(const Duration(milliseconds: 300), () => _openNumPad(_ActiveField.password));
        }
      });
    }
  }

  Future<void> _saveRememberMe(AuthProvider auth) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', _rememberMe);
    if (_rememberMe) {
      final fullName = '${auth.user?.firstName ?? ''} ${auth.user?.lastName ?? ''}'.trim();
      
      await prefs.setString('saved_username', _actualUsername ?? _usernameController.text.trim().replaceAll(' ', ''));
      await prefs.setString('saved_display_name', fullName.isNotEmpty ? fullName : (_actualUsername ?? _usernameController.text));
    } else {
      await prefs.remove('saved_username');
      await prefs.remove('saved_display_name');
    }
  }

  // ── NumPad yönetimi ───────────────────────────────────────────────────────
  void _openNumPad(_ActiveField field) {
    FocusScope.of(context).unfocus();
    HapticFeedback.mediumImpact();
    setState(() => _activeField = field);
    _numPadAnim.forward();
  }

  void _closeNumPad() {
    _numPadAnim.reverse().then((_) {
      if (mounted) setState(() => _activeField = _ActiveField.none);
    });
  }

  bool get _numPadVisible => _activeField != _ActiveField.none;

  // ── Tuş girişi ────────────────────────────────────────────────────────────
  void _onKey(String digit) {
    HapticFeedback.heavyImpact();
    if (_activeField == _ActiveField.username && _usernameIsNumeric) {
      final current = _usernameController.text;
      if (current.length < 11) {
        setState(() => _usernameController.text = current + digit);
        if (_usernameController.text.length == 11) {
          _closeNumPad();
          Future.delayed(const Duration(milliseconds: 300), () => _openNumPad(_ActiveField.password));
        }
      }
    } else if (_activeField == _ActiveField.password) {
      if (_passwordController.text.length < _pinLength) {
        setState(() => _passwordController.text += digit);
        if (_passwordController.text.length == _pinLength) {
          _closeNumPad();
          Future.delayed(const Duration(milliseconds: 320), _login);
        }
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.mediumImpact();
    if (_activeField == _ActiveField.username && _usernameIsNumeric) {
      final t = _usernameController.text;
      if (t.isNotEmpty) {
        setState(() => _usernameController.text = t.substring(0, t.length - 1));
      }
    } else if (_activeField == _ActiveField.password) {
      if (_passwordController.text.isNotEmpty) setState(() => _passwordController.text = _passwordController.text.substring(0, _passwordController.text.length - 1));
    }
  }

  Future<void> _login() async {
    final loginUsername = _actualUsername ?? _usernameController.text.trim().replaceAll(' ', '');
    
    if (loginUsername.isEmpty) {
      _showSnack('Lütfen müşteri no / kullanıcı adınızı girin.', isError: false);
      setState(() => _passwordController.clear());
      return;
    }



    if (_passwordController.text.isEmpty) {
      _showSnack('Lütfen şifrenizi girin.', isError: false);
      return;
    }
    try {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      await auth.login(loginUsername, _passwordController.text);
          
      if (loginUsername.toLowerCase() != 'demo') {
        await _saveRememberMe(auth);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _passwordController.clear());
        _showSnack('Hatalı müşteri no veya şifre.', isError: true);
      }
    }
  }

  Future<void> _demoLogin() async {
    _closeNumPad();
    FocusScope.of(context).unfocus();
    setState(() {
      _actualUsername = null;
      _usernameController.text = 'demo';
      _passwordController.text = '123456';
      _usernameIsNumeric = false;
      _passwordIsNumeric = true;
    });
    await Future.delayed(const Duration(milliseconds: 350));
    await _login();
  }

  void _showForgotPasswordDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Şifre Sıfırlama'),
        content: const Text('Şifrenizi sıfırlamak için hesabınıza bağlı e-posta adresini girin, size bir sıfırlama bağlantısı göndereceğiz.'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            style: TextButton.styleFrom(foregroundColor: _kSubText),
            child: const Text('İptal'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              _showSnack('Sıfırlama bağlantısı gönderildi.', isError: false);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlueMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
            child: const Text('Gönder'),
          ),
        ],
      ),
    );
  }

  void _showSnack(String msg, {required bool isError}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? const Color(0xFFD32F2F) : _kBlueMid,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;
    final mq = MediaQuery.of(context);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: const SystemUiOverlayStyle(
        statusBarColor: _kBlueDark,
        statusBarIconBrightness: Brightness.light,
      ),
      child: PopScope(
        canPop: false,
        child: Scaffold(
          backgroundColor: _kBg,
          resizeToAvoidBottomInset: false,
        body: GestureDetector(
          onTap: _numPadVisible ? _closeNumPad : null,
          behavior: HitTestBehavior.translucent,
          child: Stack(
            children: [
              // ── Arka plan dalgası ──────────────────────────────────────
              _BgWave(),

              // ── SafeArea içerik ────────────────────────────────────────
              SafeArea(
                child: Column(
                  children: [
                    // Header
                    _buildHeader(),

                    // Kaydırılabilir form kartı
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const ClampingScrollPhysics(),
                        padding: EdgeInsets.only(
                          left: 20, right: 20, top: 20,
                          bottom: _numPadVisible ? mq.size.height * 0.5 : 16,
                        ),
                        child: Column(
                          children: [
                            _buildFormCard(isLoading),
                            const SizedBox(height: 16),
                            // Demo + Kayıt Ol
                            _buildSecondaryActions(isLoading),
                          ],
                        ),
                      ),
                    ),

                    // Alt araçlar çubuğu
                    _buildBottomTools(),
                  ],
                ),
              ),

              // ── NumPad overlay ─────────────────────────────────────────
              if (_numPadVisible || _numPadAnim.value > 0)
                _buildNumPadOverlay(mq),
            ],
          ),
        ),
      ),
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      color: _kBlueDark,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / marka
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                alignment: Alignment.center,
                child: const Text(
                  'O',
                  style: TextStyle(
                    color: _kBlueDark,
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    letterSpacing: -1,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'FinansApp',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3,
                    ),
                  ),
                  Text(
                    'Kişisel Finans Yönetimi',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      letterSpacing: 0.2,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 22),
          const Text(
            'Güvenli Giriş',
            style: TextStyle(
              color: Colors.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Hesabınıza erişmek için bilgilerinizi girin.',
            style: TextStyle(color: Colors.white60, fontSize: 13),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
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
      child: Column(
        children: [
          // ── Müşteri No / Kullanıcı adı ─────────────────────────────────
          if (_isRememberedUser)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: _kBlueMid.withOpacity(0.1),
                    child: const Icon(Icons.person, color: _kBlueMid),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _usernameController.text, // Display name
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _kText,
                          ),
                        ),
                        const SizedBox(height: 4),
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _actualUsername = null;
                              _usernameController.text = '';
                              _usernameIsNumeric = true;
                            });
                          },
                          child: const Text(
                            'Farklı Kullanıcı ile Giriş Yap',
                            style: TextStyle(
                              color: _kBlueMid,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else if (_usernameIsNumeric)
            _FieldTile(
              label: 'Müşteri No / TCKN / Telefon',
              value: _usernameController.text,
              icon: Icons.person_outline_rounded,
              isActive: _activeField == _ActiveField.username,
              isPassword: false,
              showKeyboardToggle: true,
              isNumericMode: true,
              onTap: () => _openNumPad(_ActiveField.username),
              onToggleMode: () => setState(() {
                _usernameIsNumeric = false;
                _activeField = _ActiveField.none;
                _numPadAnim.reverse();
                Future.delayed(const Duration(milliseconds: 100),
                    () => _usernameFocusNode.requestFocus());
              }),
            )
          else
            _NativeInputField(
              controller: _usernameController,
              focusNode: _usernameFocusNode,
              nextFocusNode: _passwordFocusNode,
              isActive: _usernameFocusNode.hasFocus,
              label: 'Müşteri No / TCKN / Telefon',
              icon: Icons.person_outline_rounded,
              onToggleToNumpad: () => setState(() {
                _usernameIsNumeric = true;
                _usernameFocusNode.unfocus();
              }),
            ),

          Divider(height: 1, color: Colors.grey.shade100),

          // ── Şifre ──────────────────────────────────────────────────────
          if (_passwordIsNumeric)
            _FieldTile(
              label: 'Şifre (PIN)',
              value: _passwordController.text,
              icon: Icons.lock_outline_rounded,
              isActive: _activeField == _ActiveField.password,
              isPassword: true,
              pinLength: _pinLength,
              isNumericMode: true,
              showKeyboardToggle: true,
              onTap: () => _openNumPad(_ActiveField.password),
              onToggleMode: () => setState(() {
                _passwordIsNumeric = false;
                _activeField = _ActiveField.none;
                _numPadAnim.reverse();
                Future.delayed(const Duration(milliseconds: 100),
                    () => _passwordFocusNode.requestFocus());
              }),
            )
          else
            _NativeInputField(
              controller: _passwordController,
              focusNode: _passwordFocusNode,
              isActive: _passwordFocusNode.hasFocus,
              label: 'Şifre',
              icon: Icons.lock_outline_rounded,
              isPassword: true,
              onToggleToNumpad: () => setState(() {
                _passwordIsNumeric = true;
                _passwordFocusNode.unfocus();
              }),
              onFieldSubmitted: (_) => _login(),
            ),

          Divider(height: 1, color: Colors.grey.shade100),

          // ── Beni Hatırla + Giriş ───────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                // Beni Hatırla
                Row(
                  children: [
                    Transform.scale(
                      scale: 0.9,
                      child: Checkbox(
                        value: _rememberMe,
                        onChanged: (v) => setState(() => _rememberMe = v ?? false),
                        activeColor: _kBlueMid,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _rememberMe = !_rememberMe),
                      child: const Text(
                        'Beni Hatırla',
                        style: TextStyle(
                          fontSize: 14,
                          color: _kText,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const Spacer(),
                    TextButton(
                      onPressed: _showForgotPasswordDialog,
                      style: TextButton.styleFrom(
                        foregroundColor: _kBlueMid,
                        padding: EdgeInsets.zero,
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Şifremi Unuttum',
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Giriş Yap butonu
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _login,
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
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Giriş Yap',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.arrow_forward_rounded, size: 20),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildSecondaryActions(bool isLoading) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: isLoading ? null : _demoLogin,
            icon: const Icon(Icons.rocket_launch_rounded, size: 18),
            label: const Text(
              'Demo Giriş',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlueMid,
              side: BorderSide(color: _kBlueMid.withOpacity(0.6), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => Navigator.pushNamed(context, '/register'),
            icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
            label: const Text(
              'Kayıt Ol',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: _kBlueDark,
              side: BorderSide(color: _kBlueDark.withOpacity(0.4), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // Alt araçlar çubuğu
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildBottomTools() {
    final tools = [
      _ToolItem(icon: Icons.calculate_outlined,    label: 'Kredi\nHesap.',    route: '/tools/loan'),
      _ToolItem(icon: Icons.currency_exchange,      label: 'Döviz\nÇevirici',  route: '/tools/converter'),
      _ToolItem(icon: Icons.trending_up_rounded,    label: 'Piyasa\nTakibi',   route: '/market'),
      _ToolItem(icon: Icons.calendar_today_outlined,label: 'Halka\nArz',       route: '/tools/ipo'),
      _ToolItem(icon: Icons.note_alt_outlined,      label: 'Notlar',           route: '/tools/notepad'),
    ];

    return Container(
      decoration: BoxDecoration(
        color: _kCard,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.07),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                const SizedBox(width: 8),
                Container(
                  width: 3,
                  height: 14,
                  decoration: BoxDecoration(
                    color: _kBlueMid,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Hızlı Araçlar',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: _kSubText,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: tools.map((t) => _buildToolButton(t)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToolButton(_ToolItem tool) {
    return GestureDetector(
      onTap: () {
        if (tool.route != null) {
          Navigator.pushNamed(context, tool.route!);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: _kBlueDark.withOpacity(0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(tool.icon, color: _kBlueDark, size: 22),
          ),
          const SizedBox(height: 5),
          Text(
            tool.label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: _kSubText,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────────────────
  // NumPad overlay (alttan kayarak gelir)
  // ─────────────────────────────────────────────────────────────────────────
  Widget _buildNumPadOverlay(MediaQueryData mq) {
    return Positioned(
      left: 0, right: 0, bottom: 0,
      child: SlideTransition(
        position: _numPadSlide,
        child: GestureDetector(
          onTap: () {}, // Tıklamayı yut (dışarıya geçme)
          child: Container(
            decoration: const BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: Color(0x22000000), blurRadius: 24, offset: Offset(0, -4)),
              ],
            ),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Tutma çizgisi + başlık
                  GestureDetector(
                    onTap: _closeNumPad,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Column(
                        children: [
                          Container(
                            width: 40, height: 4,
                            decoration: BoxDecoration(
                              color: Colors.grey.shade300,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            _activeField == _ActiveField.username
                                ? 'Müşteri No / Tel Girin'
                                : 'PIN Şifrenizi Girin',
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _kBlueDark,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // PIN göstergesi (şifre alanı açıksa)
                  if (_activeField == _ActiveField.password)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildPinDots(),
                    ),

                  // Kullanıcı adı göstergesi (username alanı açıksa)
                  if (_activeField == _ActiveField.username)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Text(
                        _usernameController.text.isEmpty
                            ? '—'
                            : _usernameController.text,
                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w700,
                          color: _kBlueDark,
                          letterSpacing: 4,
                        ),
                      ),
                    ),

                  // NumPad
                  _buildNumPad(),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPinDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(_pinLength, (i) {
        final filled = i < _passwordController.text.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.symmetric(horizontal: 8),
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _kBlueMid : Colors.grey.shade200,
            border: Border.all(
              color: filled ? _kBlueMid : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }

  Widget _buildNumPad() {
    const rows = [
      [1, 2, 3],
      [4, 5, 6],
      [7, 8, 9],
    ];
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 36),
      child: Column(
        children: [
          ...rows.map((row) => _buildNumRow(row)),
          _buildBottomNumRow(),
        ],
      ),
    );
  }

  Widget _buildNumRow(List<int> numbers) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: numbers.map(_buildNumKey).toList(),
      ),
    );
  }

  Widget _buildBottomNumRow() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        // Boş / Parmak izi placeholder
        _buildIconKey(Icons.fingerprint_rounded, onTap: null),
        _buildNumKey(0),
        _buildIconKey(Icons.backspace_outlined, onTap: _onBackspace),
      ],
    );
  }

  static const Map<int, String> _numLetters = {
    1: '', 2: 'A B C', 3: 'D E F',
    4: 'G H I', 5: 'J K L', 6: 'M N O',
    7: 'P Q R S', 8: 'T U V', 9: 'W X Y Z',
    0: '+',
  };

  Widget _buildNumKey(int n) {
    return _NumKey(
      label: n.toString(),
      letters: _numLetters[n] ?? '',
      onTap: () => _onKey(n.toString()),
    );
  }

  Widget _buildIconKey(IconData icon, {VoidCallback? onTap}) {
    return _NumKey(
      icon: icon,
      onTap: onTap,
    );
  }
}

// ══════════════════════════════════════════════════════════════════════════════
// Yardımcı Widgetlar
// ══════════════════════════════════════════════════════════════════════════════

class _NumKey extends StatefulWidget {
  final String? label;
  final String? letters;
  final IconData? icon;
  final VoidCallback? onTap;

  const _NumKey({this.label, this.letters, this.icon, this.onTap});

  @override
  State<_NumKey> createState() => _NumKeyState();
}

class _NumKeyState extends State<_NumKey> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    // Görünmez bir tuş (örneğin sol alt köşedeki boş buton) ise tıklamayı kapat
    if (widget.onTap == null) {
      return const SizedBox(width: 76, height: 76);
    }

    return GestureDetector(
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) {
        setState(() => _isPressed = false);
        widget.onTap!();
      },
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 100),
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: _isPressed ? const Color(0xFFD1D5DB) : const Color(0xFFF3F4F6),
          boxShadow: _isPressed
              ? []
              : [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.icon != null)
              Icon(
                widget.icon,
                size: 30,
                color: _kText,
              )
            else ...[
              Text(
                widget.label ?? '',
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w400,
                  color: _kText,
                  height: 1.0,
                ),
              ),
              if (widget.letters != null && widget.letters!.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: Text(
                    widget.letters!,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: _kSubText,
                      letterSpacing: 1.5,
                      height: 1.0,
                    ),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _FieldTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final bool isActive;
  final bool isPassword;
  final int? pinLength;
  final bool isNumericMode;
  final bool showKeyboardToggle;
  final VoidCallback onTap;
  final VoidCallback? onToggleMode;

  const _FieldTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.isActive,
    required this.isPassword,
    required this.isNumericMode,
    required this.onTap,
    this.pinLength,
    this.showKeyboardToggle = false,
    this.onToggleMode,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          color: isActive ? _kBlueMid.withOpacity(0.04) : Colors.transparent,
          borderRadius: BorderRadius.circular(4),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 22, color: isActive ? _kBlueMid : _kSubText),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11,
                      color: isActive ? _kBlueMid : _kSubText,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.3,
                    ),
                  ),
                  const SizedBox(height: 6),
                  isPassword
                      ? _PinDisplay(value: value, length: pinLength ?? 6)
                      : Text(
                          value.isEmpty ? 'Girmek için dokunun' : value,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            letterSpacing: value.isEmpty ? 0 : 2,
                            color: value.isEmpty ? _kSubText.withOpacity(0.5) : _kText,
                          ),
                        ),
                ],
              ),
            ),
            // Klavye/numpad toggle (sadece username için)
            if (showKeyboardToggle && onToggleMode != null)
              IconButton(
                onPressed: onToggleMode,
                icon: Icon(
                  isNumericMode ? Icons.keyboard_alt_outlined : Icons.dialpad_rounded,
                  size: 20,
                  color: _kBlueMid,
                ),
                tooltip: isNumericMode ? 'Klavyeye geç' : 'Tuş takımına geç',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
              ),
            Icon(
              Icons.chevron_right_rounded,
              color: isActive ? _kBlueMid : Colors.grey.shade300,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _PinDisplay extends StatelessWidget {
  final String value;
  final int length;

  const _PinDisplay({required this.value, required this.length});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(length, (i) {
        final filled = i < value.length;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          margin: const EdgeInsets.only(right: 10),
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? _kBlueMid : Colors.grey.shade200,
            border: Border.all(
              color: filled ? _kBlueMid : Colors.grey.shade400,
              width: 1.5,
            ),
          ),
        );
      }),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Arka plan mavi dalga dekorasyonu
// ─────────────────────────────────────────────────────────────────────────────
class _BgWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0, right: 0, top: 0,
      child: CustomPaint(
        size: Size(MediaQuery.of(context).size.width, 260),
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

class _NativeInputField extends StatelessWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final FocusNode? nextFocusNode;
  final bool isActive;
  final String label;
  final IconData icon;
  final bool isPassword;
  final VoidCallback onToggleToNumpad;
  final void Function(String)? onFieldSubmitted;

  const _NativeInputField({
    required this.controller,
    required this.focusNode,
    this.nextFocusNode,
    required this.isActive,
    required this.label,
    required this.icon,
    this.isPassword = false,
    required this.onToggleToNumpad,
    this.onFieldSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isActive ? _kBlueMid.withOpacity(0.04) : Colors.transparent,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      child: Row(
        children: [
          Icon(icon, size: 22, color: _kBlueMid),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 11,
                    color: _kBlueMid,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
                TextField(
                  controller: controller,
                  focusNode: focusNode,
                  textInputAction: nextFocusNode != null ? TextInputAction.next : TextInputAction.done,
                  onSubmitted: onFieldSubmitted ?? (nextFocusNode != null ? (_) => FocusScope.of(context).requestFocus(nextFocusNode) : null),
                  obscureText: isPassword,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _kText,
                  ),
                  decoration: const InputDecoration(
                    isDense: true,
                    contentPadding: EdgeInsets.symmetric(vertical: 8),
                    border: InputBorder.none,
                    hintText: 'Girin...',
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onToggleToNumpad,
            icon: const Icon(Icons.dialpad_rounded, size: 20, color: _kBlueMid),
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
class _ToolItem {
  final IconData icon;
  final String label;
  final String? route;
  const _ToolItem({required this.icon, required this.label, this.route});
}
