import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';

/// Placeholder for the mobile Profile tab.
class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: FluxerColors.backgroundPrimary,
      child: const Center(
        child: Text(
          'Profile',
          style: const TextStyle(
            color: FluxerColors.textMuted,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
