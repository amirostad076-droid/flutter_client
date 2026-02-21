import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserPanel extends ConsumerWidget {
  final VoidCallback? onSettingsTap;

  const UserPanel({this.onSettingsTap, super.key});

  static const height = 60.0;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userSettingsViewModelProvider);

    return Container(
      height: height,
      decoration: const BoxDecoration(
        color: FluxerColors.userPanelBackground,
        border: Border(
          top: BorderSide(color: FluxerColors.separator),
          right: BorderSide(color: FluxerColors.separator),
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      child: Row(
        children: [
          const SizedBox(width: 2),
          UserAvatar(
            displayName: user.displayName,
            avatarUrl: user.avatarUrl,
            avatarColor: user.avatarColor,
            size: 34,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.displayName,
                  style: const TextStyle(
                    color: FluxerColors.textNormal,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${user.username}#${user.discriminator}',
                  style: const TextStyle(
                    color: FluxerColors.textMuted,
                    fontSize: 12,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.microphone, size: 20),
            color: FluxerColors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.headphones, size: 20),
            color: FluxerColors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.gear, size: 20),
            color: FluxerColors.interactiveNormal,
            onPressed: onSettingsTap,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
          ),
        ],
      ),
    );
  }
}
