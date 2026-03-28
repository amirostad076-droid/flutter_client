import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserArea extends ConsumerWidget {
  final VoidCallback? onSettingsTap;

  const UserArea({this.onSettingsTap, super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userSettingsViewModelProvider);
    final layout = context.layout;
    final colors = context.colors;

    return Container(
      constraints: BoxConstraints(minHeight: layout.userAreaHeight),
      decoration: BoxDecoration(
        color: colors.userPanelBackground,
        border: Border(top: BorderSide(color: colors.borderColor)),
      ),
      padding: EdgeInsets.symmetric(horizontal: layout.s2, vertical: layout.s2),
      child: Row(
        children: [
          Expanded(
            child: Material(
              color: Colors.transparent,
              borderRadius: layout.radiusMd,
              child: InkWell(
                borderRadius: layout.radiusMd,
                hoverColor: colors.textPrimary.withValues(alpha: 0.03),
                onTap: () {},
                child: Padding(
                  padding: EdgeInsets.symmetric(horizontal: layout.s2),
                  child: SizedBox(
                    height: 40,
                    child: Row(
                      children: [
                        FluxerAvatar.user(
                          fallbackText: user.displayName,
                          userId: user.userId,
                          imageUrl: user.avatarUrl,
                          avatarColor: user.avatarColor,
                          size: 36,
                        ),
                        SizedBox(width: layout.s2),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.displayName,
                                style: TextStyle(
                                  color: colors.textPrimary,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  height: 18 / 14,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 1),
                              Text(
                                '${user.username}#${user.discriminator}',
                                style: TextStyle(
                                  color: colors.textPrimaryMuted.withValues(
                                    alpha: 0.85,
                                  ),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w500,
                                  height: 16 / 11,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          SizedBox(width: layout.s3),
          _ControlButton(
            icon: PhosphorIconsFill.microphone,
            color: colors.interactiveNormal,
            onPressed: () {},
          ),
          SizedBox(width: layout.s1),
          _ControlButton(
            icon: PhosphorIconsRegular.speakerHigh,
            color: colors.interactiveNormal,
            onPressed: () {},
          ),
          SizedBox(width: layout.s1),
          _ControlButton(
            icon: PhosphorIconsRegular.gear,
            color: colors.interactiveNormal,
            onPressed: onSettingsTap,
          ),
        ],
      ),
    );
  }
}

class _ControlButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback? onPressed;

  const _ControlButton({
    required this.icon,
    required this.color,
    this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 32,
      height: 32,
      child: Material(
        color: Colors.transparent,
        borderRadius: context.layout.radiusMd,
        child: InkWell(
          borderRadius: context.layout.radiusMd,
          hoverColor: color.withValues(alpha: 0.1),
          onTap: onPressed,
          child: Center(child: PhosphorIcon(icon, size: 20, color: color)),
        ),
      ),
    );
  }
}
