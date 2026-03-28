import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/shared/widgets/profile_content.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';

class ProfilePage extends ConsumerWidget {
  const ProfilePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final UserSettingsViewState state = ref.watch(
      userSettingsViewModelProvider,
    );
    return Scaffold(
      backgroundColor: context.colors.backgroundPrimary,
      body: ProfileContent(
        userId: state.userId,
        displayName: state.displayName,
        username: state.username,
        discriminator: state.discriminator,
        avatarUrl: state.avatarUrl,
        avatarColor: state.avatarColor,
      ),
    );
  }
}
