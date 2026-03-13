import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/settings/presentation/user_settings_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: FluxerColors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor: FluxerColors.backgroundPrimary,
        title: const Text('You'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const PhosphorIcon(
              PhosphorIconsRegular.gear,
              color: FluxerColors.interactiveNormal,
            ),
            onPressed: () => UserSettingsScreen.show(context),
          ),
        ],
      ),
      body: const Center(
        child: Text(
          'Profile',
          style: TextStyle(
            color: FluxerColors.textMuted,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
