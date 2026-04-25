import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ThemeSwatchButton extends StatelessWidget {
  const ThemeSwatchButton({
    required this.label,
    required this.backgroundColor,
    required this.isSelected,
    required this.onTap,
    this.centerIcon,
    super.key,
  });

  final String label;
  final Color backgroundColor;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? centerIcon;

  static const double _size = 56;
  static const double _checkmarkSize = 20;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onLightBackground = _estimateLuminance(backgroundColor) > 0.5;
    final contrastColor = onLightBackground ? Colors.black : Colors.white;
    final borderColor = isSelected
        ? colors.brandPrimary
        : onLightBackground
        ? colors.borderColor
        : colors.textPrimary;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: SizedBox(
        width: _size,
        height: _size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: Material(
                color: backgroundColor,
                shape: CircleBorder(
                  side: BorderSide(color: borderColor, width: 2),
                ),
                child: InkWell(
                  onTap: onTap,
                  customBorder: const CircleBorder(),
                  child: centerIcon == null
                      ? const SizedBox.expand()
                      : Center(
                          child: PhosphorIcon(
                            centerIcon!,
                            size: 24,
                            color: contrastColor,
                          ),
                        ),
                ),
              ),
            ),
            if (isSelected)
              Positioned(
                top: -4,
                right: -4,
                child: Container(
                  width: _checkmarkSize,
                  height: _checkmarkSize,
                  decoration: BoxDecoration(
                    color: colors.brandPrimary,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: PhosphorIcon(
                      PhosphorIconsBold.check,
                      size: 12,
                      color: colors.textOnBrandPrimary,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  static double _estimateLuminance(Color color) {
    return (0.299 * (color.r * 255) +
            0.587 * (color.g * 255) +
            0.114 * (color.b * 255)) /
        255;
  }
}
