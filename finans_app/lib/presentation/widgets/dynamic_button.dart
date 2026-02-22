import 'package:flutter/material.dart';
import 'package:finans_app/core/theme/app_theme.dart';

class DynamicButton extends StatefulWidget {
  final String label;
  final VoidCallback? onTap;
  final Color? color;
  final IconData? icon;
  final bool isLoading;
  final double? width;
  final double height;

  const DynamicButton({
    super.key,
    required this.label,
    required this.onTap,
    this.color,
    this.icon,
    this.isLoading = false,
    this.width,
    this.height = 56,
  });

  @override
  State<DynamicButton> createState() => _DynamicButtonState();
}

class _DynamicButtonState extends State<DynamicButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
      lowerBound: 0.0,
      upperBound: 0.05,
    )..addListener(() {
        setState(() {});
      });
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.95).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.onTap != null) _controller.forward();
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null) _controller.reverse();
  }

  void _onTapCancel() {
    if (widget.onTap != null) _controller.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final buttonColor = widget.color ?? AppTheme.primaryColor;

    return GestureDetector(
      onTapDown: _onTapDown,
      onTapUp: _onTapUp,
      onTapCancel: _onTapCancel,
      onTap: widget.isLoading ? null : widget.onTap,
      child: Transform.scale(
        scale: _scaleAnimation.value,
        child: Container(
          width: widget.width ?? double.infinity,
          height: widget.height,
          decoration: BoxDecoration(
            color: widget.onTap == null
                ? Colors.grey.withValues(alpha: 0.3)
                : buttonColor,
            borderRadius: BorderRadius.circular(16),
            boxShadow: widget.onTap == null
                ? []
                : [
                    BoxShadow(
                      color: buttonColor.withValues(alpha: 0.3),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
            gradient: widget.onTap == null
                ? null
                : LinearGradient(
                    colors: [buttonColor, buttonColor.withValues(alpha: 0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (widget.icon != null) ...[
                        Icon(widget.icon, color: Colors.white, size: 20),
                        const SizedBox(width: 8),
                      ],
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
