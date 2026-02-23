import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class FadeIconButton extends StatefulWidget {
  const FadeIconButton({
    super.key,
    required this.icon,
    required this.iconColor,
    required this.onTap,
    this.size = 24,
    this.padding = EdgeInsets.zero,
  });

  final IconData icon;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;
  final EdgeInsetsGeometry padding;

  @override
  State<FadeIconButton> createState() => _FadeIconButtonState();
}

class _FadeIconButtonState extends State<FadeIconButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (_) => setState(() => _isPressed = true),
      onTapUp: (_) => setState(() => _isPressed = false),
      onTapCancel: () => setState(() => _isPressed = false),
      child: AnimatedOpacity(
        opacity: _isPressed ? 0.4 : 1.0,
        duration: _isPressed
            ? const Duration(milliseconds: 50)
            : const Duration(milliseconds: 200),
        child: Padding(
          padding: widget.padding,
          child: PhosphorIcon(widget.icon, size: widget.size, color: widget.iconColor),
        ),
      ),
    );
  }
}
