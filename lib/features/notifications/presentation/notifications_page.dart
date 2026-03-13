import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';

/// Placeholder for the mobile Notifications tab.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: FluxerColors.backgroundPrimary,
      child: Center(
        child: Text(
          'Notifications',
          style: TextStyle(
            color: FluxerColors.textMuted,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
