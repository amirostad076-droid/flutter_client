import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';

/// Placeholder for the mobile Notifications tab.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluxerColors.backgroundPrimary,
      child: const Center(
        child: Text(
          'Notifications',
          style: const TextStyle(
            color: FluxerColors.textMuted,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
