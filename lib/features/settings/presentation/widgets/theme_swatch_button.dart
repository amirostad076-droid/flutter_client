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

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final onLightBackground = _estimateLuminance(backgroundColor) > 0.5;
    final contrastColor = onLightBackground ? Colors.black : Colors.white;

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: AspectRatio(
        aspectRatio: 1.2,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: backgroundColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isSelected
                          ? colors.brandPrimary
                          : colors.borderColor,
                      width: isSelected ? 2 : 1,
                    ),
                  ),
                ),
                if (centerIcon != null)
                  Center(
                    child: PhosphorIcon(
                      centerIcon!,
                      size: 28,
                      color: contrastColor,
                    ),
                  ),
                if (isSelected)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 20,
                      height: 20,
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
