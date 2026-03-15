import 'package:flutter/material.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class PillButton extends StatefulWidget {
  const PillButton({
    this.icon,
    required this.text,
    required this.backgroundColor,
    this.iconColor,
    required this.onTap,
    super.key,
    this.height = 36,
    this.iconSize = 20,
  });

  final IconData? icon;
  final String text;
  final Color backgroundColor;
  final Color? iconColor;
  final VoidCallback onTap;
  final double height;
  final double iconSize;

  @override
  State<PillButton> createState() => _PillButtonState();
}

class _PillButtonState extends State<PillButton> {
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
          height: widget.height,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: widget.backgroundColor,
            borderRadius: BorderRadius.circular(widget.height),
          ),
          child: Row(
            spacing: 5,
            children: [
              if (widget.icon != null)
                PhosphorIcon(
                  widget.icon!,
                  size: widget.iconSize,
                  color: widget.iconColor,
                ),
              Text(
                widget.text,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
