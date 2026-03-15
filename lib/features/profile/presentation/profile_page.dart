import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/settings/presentation/user_settings_screen.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          context.colors.backgroundPrimary,
      appBar: AppBar(
        backgroundColor:
            context.colors.backgroundPrimary,
        title: const Text('You'),
        centerTitle: true,
        actions: [
          IconButton(
            icon: PhosphorIcon(
              PhosphorIconsRegular.gear,
              color:
                  context.colors.interactiveNormal,
            ),
            onPressed: () =>
                UserSettingsScreen.show(context),
          ),
        ],
      ),
      body: Center(
        child: Text(
          'Profile',
          style: TextStyle(
            color: context.colors.textPrimaryMuted,
            fontSize: 18,
          ),
        ),
      ),
    );
  }
}
