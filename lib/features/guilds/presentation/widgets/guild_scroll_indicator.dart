import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

enum ScrollIndicatorSeverity { unread, mention }

class GuildScrollIndicator extends StatelessWidget {
  final ScrollIndicatorSeverity severity;
  final VoidCallback onTap;

  const GuildScrollIndicator({
    required this.severity,
    required this.onTap,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bgColor = switch (severity) {
      ScrollIndicatorSeverity.mention => colors.statusDanger,
      ScrollIndicatorSeverity.unread => colors.textSecondary.withValues(
        alpha: 0.6,
      ),
    };

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(999),
          boxShadow: const [
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.45),
              blurRadius: 6,
              offset: Offset(0, 4),
            ),
            BoxShadow(
              color: Color.fromRGBO(0, 0, 0, 0.35),
              blurRadius: 20,
              offset: Offset(0, 10),
            ),
          ],
        ),
        child: Text(
          'NEW',
          style: TextStyle(
            color: colors.textOnBrandPrimary,
            fontSize: 11,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.3,
          ),
        ),
      ),
    );
  }
}
