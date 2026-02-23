import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class CircleIconButton extends StatefulWidget {
  const CircleIconButton({
    required this.icon, required this.backgroundColor, required this.iconColor, required this.onTap, super.key,
    this.size = 36,
    this.iconSize = 20,
  });

  final IconData icon;
  final Color backgroundColor;
  final Color iconColor;
  final VoidCallback onTap;
  final double size;
  final double iconSize;

  @override
  State<CircleIconButton> createState() => _CircleIconButtonState();
}

class _CircleIconButtonState extends State<CircleIconButton> {
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
        child: Container(
          width: widget.size,
          height: widget.size,
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            shape: BoxShape.circle,
          ),
          child: Center(
            child: PhosphorIcon(
              widget.icon,
              size: widget.iconSize,
              color: widget.iconColor,
            ),
          ),
        ),
      ),
    );
  }
}
