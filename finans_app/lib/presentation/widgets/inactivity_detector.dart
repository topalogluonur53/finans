import 'package:flutter/material.dart';

/// Kullanıcı etkileşimlerini (dokunma, kaydırma, tuş) algılayarak
/// [onActivity] callback'ini tetikleyen şeffaf sarmalayıcı.
class InactivityDetector extends StatelessWidget {
  final Widget child;
  final VoidCallback onActivity;

  const InactivityDetector({
    super.key,
    required this.child,
    required this.onActivity,
  });

  @override
  Widget build(BuildContext context) {
    return Listener(
      behavior: HitTestBehavior.translucent,
      onPointerDown: (_) => onActivity(),
      onPointerMove: (_) => onActivity(),
      child: KeyboardListener(
        focusNode: FocusNode(),
        onKeyEvent: (_) => onActivity(),
        child: child,
      ),
    );
  }
}
