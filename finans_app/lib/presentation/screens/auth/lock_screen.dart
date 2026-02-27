import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:finans_app/data/providers/auth_provider.dart';

// ── Renk sabitleri (login_screen ile aynı palet) ──────────────────────────
const _kBlueDark = Color(0xFF002F6C);
const _kBlueMid  = Color(0xFF0057B8);
const _kBg       = Color(0xFFF0F4FA);
const _kCard     = Color(0xFFFFFFFF);
const _kText     = Color(0xFF1A1A2E);
const _kSubText  = Color(0xFF6B7280);

class LockScreen extends StatefulWidget {
  const LockScreen({super.key});

  @override
  State<LockScreen> createState() => _LockScreenState();
}

class _LockScreenState extends State<LockScreen>
    with SingleTickerProviderStateMixin {
  // Numpad girişi
  String _pin = '';
  static const int _pinLength = 6;

  // Klavye modu (sayısal olmayan pin için)
  bool _useKeyboard = false;
  final _keyboardController = TextEditingController();
  final _keyboardFocus = FocusNode();

  bool _isLoading = false;
  String? _errorMsg;

  // Sallama animasyonu (yanlış şifre)
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  // Klavye kısayol dinleyicisi (web/PC)
  final FocusNode _keyListenerFocus = FocusNode();

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
    // Klavye dinleyicisine fokus ver
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _keyListenerFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _shakeCtrl.dispose();
    _keyboardController.dispose();
    _keyboardFocus.dispose();
    _keyListenerFocus.dispose();
    super.dispose();
  }

  // ── Klavye (PC/Web) tuş girişi ─────────────────────────────────────────
  KeyEventResult _handleKeyEvent(FocusNode node, KeyEvent event) {
    if (event is! KeyDownEvent) return KeyEventResult.ignored;
    if (_useKeyboard) return KeyEventResult.ignored;

    final key = event.logicalKey;

    // Sayısal tuşlar (numpad veya üst sıra)
    final numKeys = {
      LogicalKeyboardKey.digit0: '0',
      LogicalKeyboardKey.digit1: '1',
      LogicalKeyboardKey.digit2: '2',
      LogicalKeyboardKey.digit3: '3',
      LogicalKeyboardKey.digit4: '4',
      LogicalKeyboardKey.digit5: '5',
      LogicalKeyboardKey.digit6: '6',
      LogicalKeyboardKey.digit7: '7',
      LogicalKeyboardKey.digit8: '8',
      LogicalKeyboardKey.digit9: '9',
      LogicalKeyboardKey.numpad0: '0',
      LogicalKeyboardKey.numpad1: '1',
      LogicalKeyboardKey.numpad2: '2',
      LogicalKeyboardKey.numpad3: '3',
      LogicalKeyboardKey.numpad4: '4',
      LogicalKeyboardKey.numpad5: '5',
      LogicalKeyboardKey.numpad6: '6',
      LogicalKeyboardKey.numpad7: '7',
      LogicalKeyboardKey.numpad8: '8',
      LogicalKeyboardKey.numpad9: '9',
    };

    if (numKeys.containsKey(key)) {
      _onNumKey(numKeys[key]!);
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.backspace || key == LogicalKeyboardKey.delete) {
      _onBackspace();
      return KeyEventResult.handled;
    }

    if (key == LogicalKeyboardKey.enter || key == LogicalKeyboardKey.numpadEnter) {
      if (_pin.isNotEmpty) _tryUnlock(_pin);
      return KeyEventResult.handled;
    }

    return KeyEventResult.ignored;
  }

  // ── Numpad tuş girişi ──────────────────────────────────────────────────
  void _onNumKey(String digit) {
    HapticFeedback.lightImpact();
    if (_pin.length < _pinLength) {
      setState(() {
        _pin += digit;
        _errorMsg = null;
      });
      if (_pin.length == _pinLength) {
        _tryUnlock(_pin);
      }
    }
  }

  void _onBackspace() {
    HapticFeedback.selectionClick();
    if (_pin.isNotEmpty) {
      setState(() => _pin = _pin.substring(0, _pin.length - 1));
    }
  }

  // ── Şifre doğrulama ────────────────────────────────────────────────────
  Future<void> _tryUnlock(String password) async {
    if (password.isEmpty) return;
    if (_isLoading) return;
    setState(() {
      _isLoading = true;
      _errorMsg = null;
    });

    try {
      final auth = context.read<AuthProvider>();
      final success = await auth.unlockWithPassword(password);

      if (!mounted) return;

      if (success) return;

      // Sunucuya erişildi ama şifre yanlış
      HapticFeedback.heavyImpact();
      _shakeCtrl.forward(from: 0);
      setState(() {
        _isLoading = false;
        _pin = '';
        _keyboardController.clear();
        _errorMsg = 'Şifre hatalı, lütfen tekrar deneyin.';
      });
    } catch (e) {
      if (!mounted) return;
      HapticFeedback.heavyImpact();
      setState(() {
        _isLoading = false;
        _pin = '';
        _keyboardController.clear();
      });
      // Sunucu bağlantı hatası → diyalog göster
      _showUnlockError(e.toString());
    }
  }

  void _showUnlockError(String details) {
    final isNetwork = details.contains('Socket') ||
        details.contains('Connection') ||
        details.contains('timeout') ||
        details.contains('Timeout');

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        icon: Icon(
          isNetwork ? Icons.wifi_off_rounded : Icons.lock_person_rounded,
          color: isNetwork ? Colors.orange : const Color(0xFFD32F2F),
          size: 48,
        ),
        title: Text(
          isNetwork ? 'Bağlantı Hatası' : 'Doğrulama Hatası',
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.w700, color: _kText),
        ),
        content: Text(
          isNetwork
              ? 'Sunucuya ulaşılamıyor.\nİnternet bağlantınızı kontrol edin\nveya tekrar deneyin.'
              : 'Şifre doğrulanamadı.\nLütfen tekrar deneyin.',
          textAlign: TextAlign.center,
          style: const TextStyle(color: _kSubText, fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.center,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _logout();
            },
            child: const Text('Çıkış Yap', style: TextStyle(color: Colors.red)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx),
            style: ElevatedButton.styleFrom(
              backgroundColor: _kBlueMid,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Tekrar Dene', style: TextStyle(fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ── Tam çıkış yap ──────────────────────────────────────────────────────
  Future<void> _logout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Çıkış Yap'),
        content: const Text('Oturumu tamamen kapatmak istiyor musunuz?'),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Çıkış Yap',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true && mounted) {
      await context.read<AuthProvider>().logout();
    }
  }

  // ── UI ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final displayName = auth.username ?? 'Kullanıcı';

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
          body: Focus(
            focusNode: _keyListenerFocus,
            onKeyEvent: _handleKeyEvent,
            child: Stack(
              children: [
                // ── Arka plan dalgası (login ile aynı) ────────────────
                _BgWave(),

                // ── İçerik ────────────────────────────────────────────
                SafeArea(
                  child: _isLoading
                      ? const Center(
                          child: CircularProgressIndicator(color: _kBlueMid),
                        )
                      : Column(
                          children: [
                            // ── Header (login gibi lacivert band) ─────
                            _buildHeader(displayName),

                            // ── İçerik ────────────────────────────────
                            Expanded(
                              child: _useKeyboard
                                  ? _buildKeyboardMode()
                                  : _buildNumpadMode(),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Header – login ekranıyla aynı yapı ─────────────────────────────────
  Widget _buildHeader(String displayName) {
    return Container(
      width: double.infinity,
      color: _kBlueDark,
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo / marka satırı
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

          // Kullanıcı avatarı + isim
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white38, width: 2),
                ),
                child: const Icon(Icons.person_rounded, color: Colors.white, size: 28),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Hoş geldiniz, $displayName',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  const Text(
                    'Devam etmek için şifrenizi girin',
                    style: TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Numpad modu ──────────────────────────────────────────────────────────
  Widget _buildNumpadMode() {
    return Column(
      children: [
        const SizedBox(height: 28),

        // PIN göstergesi
        AnimatedBuilder(
          animation: _shakeAnim,
          builder: (ctx, child) {
            final offset = _shakeCtrl.isAnimating
                ? 10 * (0.5 - _shakeAnim.value).abs() * 2
                : 0.0;
            return Transform.translate(
              offset: Offset(offset, 0),
              child: child,
            );
          },
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(_pinLength, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    margin: const EdgeInsets.symmetric(horizontal: 8),
                    width: 16,
                    height: 16,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: filled ? _kBlueMid : Colors.transparent,
                      border: Border.all(
                        color: filled ? _kBlueMid : Colors.grey.shade400,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),
              // Hata mesajı
              if (_errorMsg != null) ...[
                const SizedBox(height: 10),
                Text(
                  _errorMsg!,
                  style: const TextStyle(color: Colors.red, fontSize: 13),
                ),
              ],
            ],
          ),
        ),

        const Spacer(),

        // Numpad (login ile aynı stil)
        _buildNumpad(),
        const SizedBox(height: 8),

        // Klavyeye geç / Çıkış yap
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            TextButton.icon(
              onPressed: () => setState(() {
                _useKeyboard = true;
                _pin = '';
                _errorMsg = null;
                Future.delayed(const Duration(milliseconds: 100), () {
                  _keyboardFocus.requestFocus();
                });
              }),
              icon: const Icon(Icons.keyboard_alt_outlined, size: 18),
              label: const Text('Klavye'),
              style: TextButton.styleFrom(foregroundColor: _kBlueMid),
            ),
            TextButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, size: 18),
              label: const Text('Çıkış Yap'),
              style: TextButton.styleFrom(foregroundColor: Colors.red.shade400),
            ),
          ],
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  // ── Klavye modu ──────────────────────────────────────────────────────────
  Widget _buildKeyboardMode() {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      child: Column(
        children: [
          // Şifre alanı
          Container(
            decoration: BoxDecoration(
              color: _kCard,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 16,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              controller: _keyboardController,
              focusNode: _keyboardFocus,
              obscureText: true,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _kText,
                letterSpacing: 4,
              ),
              decoration: InputDecoration(
                labelText: 'Şifreniz',
                labelStyle: const TextStyle(color: _kBlueMid),
                prefixIcon: const Icon(Icons.lock_outline, color: _kBlueMid),
                filled: true,
                fillColor: _kCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(color: _kBlueMid, width: 2),
                ),
                errorText: _errorMsg,
              ),
              onSubmitted: (val) => _tryUnlock(val),
            ),
          ),

          const SizedBox(height: 24),

          // Giriş butonu
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _tryUnlock(_keyboardController.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: _kBlueMid,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Devam Et',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  SizedBox(width: 8),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Geri / Çıkış
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              TextButton.icon(
                onPressed: () => setState(() {
                  _useKeyboard = false;
                  _keyboardController.clear();
                  _errorMsg = null;
                  Future.delayed(const Duration(milliseconds: 100), () {
                    _keyListenerFocus.requestFocus();
                  });
                }),
                icon: const Icon(Icons.dialpad_rounded, size: 18),
                label: const Text('Tuş Takımı'),
                style: TextButton.styleFrom(foregroundColor: _kBlueMid),
              ),
              TextButton.icon(
                onPressed: _logout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text('Çıkış Yap'),
                style: TextButton.styleFrom(
                    foregroundColor: Colors.red.shade400),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Numpad grid (login ile aynı stil) ────────────────────────────────────
  Widget _buildNumpad() {
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
        _buildIconKey(Icons.keyboard_alt_outlined, onTap: () {
          setState(() {
            _useKeyboard = true;
            _pin = '';
            _errorMsg = null;
            Future.delayed(const Duration(milliseconds: 100), () {
              _keyboardFocus.requestFocus();
            });
          });
        }),
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
      onTap: () => _onNumKey(n.toString()),
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
// iOS-tarzı Numpad Tuş Widget'ı
// • onTapDown'da callback ANINDA tetiklenir (0 ms gecikme)
// • Animasyon paralel çalışır → hızlı sıralı tuş girişini engellemez
// • lightImpact her tuşa, selectionClick backspace'e
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

class _NumKeyState extends State<_NumKey>
    with SingleTickerProviderStateMixin {
  bool _pressed = false;
  late AnimationController _pressCtrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _brightnessAnim;

  @override
  void initState() {
    super.initState();
    _pressCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 25),
      reverseDuration: const Duration(milliseconds: 90),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 0.88).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
    _brightnessAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _pressCtrl, curve: Curves.easeOut),
    );
  }

  @override
  void dispose() {
    _pressCtrl.dispose();
    super.dispose();
  }

  void _onPointerDown(PointerDownEvent _) {
    if (widget.onTap == null) return;
    HapticFeedback.lightImpact();
    widget.onTap!();
    _pressCtrl.stop();
    if (mounted) {
      setState(() => _pressed = true);
      _pressCtrl.forward(from: 0.0);
    }
  }

  void _onPointerUp(PointerUpEvent _) {
    if (!mounted) return;
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  void _onPointerCancel(PointerCancelEvent _) {
    if (!mounted) return;
    setState(() => _pressed = false);
    _pressCtrl.reverse();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.onTap == null && widget.icon == null && widget.label == null) {
      return const SizedBox(width: 80, height: 80);
    }

    if (widget.onTap == null) {
      return SizedBox(
        width: 80, height: 80,
        child: Center(
          child: widget.icon != null
              ? Icon(widget.icon, size: 28, color: Colors.white.withOpacity(0.5))
              : null,
        ),
      );
    }

    return Listener(
      onPointerDown: _onPointerDown,
      onPointerUp: _onPointerUp,
      onPointerCancel: _onPointerCancel,
      behavior: HitTestBehavior.opaque,
      child: AnimatedBuilder(
        animation: _pressCtrl,
        builder: (context, _) {
          final t = _brightnessAnim.value;
          final bgColor = Color.lerp(
            Colors.white.withOpacity(0.22),
            Colors.white.withOpacity(0.09),
            t,
          )!;
          final textColor = Color.lerp(
            Colors.white,
            Colors.white.withOpacity(0.7),
            t,
          )!;
          final subColor = Color.lerp(
            Colors.white.withOpacity(0.55),
            Colors.white.withOpacity(0.3),
            t,
          )!;

          return Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: bgColor,
                boxShadow: _pressed
                    ? []
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (widget.icon != null)
                    Icon(widget.icon, size: 28, color: textColor)
                  else ...[
                    Text(
                      widget.label ?? '',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w300,
                        color: textColor,
                        height: 1.0,
                      ),
                    ),
                    if (widget.letters != null && widget.letters!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 1),
                        child: Text(
                          widget.letters!,
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: subColor,
                            letterSpacing: 2.0,
                            height: 1.0,
                          ),
                        ),
                      ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}


// ── Arka plan dalgası (login_screen ile aynı) ─────────────────────────────
class _BgWave extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: 0,
      right: 0,
      top: 0,
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
