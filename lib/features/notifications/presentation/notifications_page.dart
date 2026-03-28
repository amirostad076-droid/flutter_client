import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

/// Placeholder for the mobile Notifications tab.
class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.backgroundPrimary,
      child: Center(
        child: Text(
          'Notifications',
          style: TextStyle(
            color: context.colors.textPrimaryMuted,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
