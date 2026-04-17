import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_badges.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_custom_status.dart';
import 'package:fluxer_dart/export.dart';

class UserProfileHeader extends StatelessWidget {
  const UserProfileHeader({
    required this.user,
    required this.profile,
    required this.customStatus,
    super.key,
  });

  final UserProfileFullResponseUser user;
  final UserProfileFullResponseUserProfile profile;
  final String? customStatus;

  String _displayName() => user.globalName ?? user.username;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final displayName = _displayName();
    final isUsernameAsDisplay = displayName == user.username;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              displayName,
              style: textStyles.heading.copyWith(
                color: colors.textPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w700,
              ),
            ),
            if (isUsernameAsDisplay)
              Text(
                '#${user.discriminator}',
                style: textStyles.heading.copyWith(
                  color: colors.textTertiary,
                  fontSize: 24,
                  fontWeight: FontWeight.w500,
                ),
              ),
          ],
        ),
        SizedBox(height: layout.s1),
        Wrap(
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 6,
          runSpacing: 4,
          children: [
            if (!isUsernameAsDisplay)
              Text(
                '${user.username}#${user.discriminator}',
                style: textStyles.bodySmall.copyWith(
                  color: colors.textTertiary,
                  fontWeight: FontWeight.w500,
                ),
              ),
            UserProfileBadges(flags: user.flags),
          ],
        ),
        SizedBox(height: layout.s1),
        UserProfileCustomStatus(text: customStatus),
      ],
    );
  }
}
