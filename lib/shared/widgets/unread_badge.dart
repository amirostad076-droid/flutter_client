import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';

class UnreadBadge extends StatelessWidget {
  final int mentionCount;
  final double size;

  const UnreadBadge({
    this.mentionCount = 0,
    this.size = 16,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (mentionCount > 0) {
      return Container(
        constraints: BoxConstraints(
          minWidth: size,
          minHeight: size,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: 4,
          vertical: 1,
        ),
        decoration: BoxDecoration(
          color: context.colors.statusDanger,
          borderRadius: BorderRadius.circular(size / 2),
        ),
        child: Center(
          child: Text(
            mentionCount > 99 ? '99+' : '$mentionCount',
            style: TextStyle(
              color: context.colors.textOnBrandPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      );
    }

    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(
        color: context.colors.textPrimary,
        shape: BoxShape.circle,
      ),
    );
  }
}
