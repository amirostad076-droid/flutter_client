import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_markdown.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';
import 'package:intl/intl.dart';

class UserProfileBioCard extends StatelessWidget {
  const UserProfileBioCard({
    required this.bio,
    required this.userId,
    super.key,
  });

  final String? bio;
  final String userId;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);
    final trimmedBio = bio?.trim();
    final hasBio = trimmedBio != null && trimmedBio.isNotEmpty;
    final memberSince = userId.isEmpty
        ? null
        : dateTimeFromUserSnowflakeOrNull(userId);

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        borderRadius: layout.radiusMd,
      ),
      child: Padding(
        padding: EdgeInsets.all(layout.s4),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (hasBio) ...[
              Text(
                l10n.userProfileAboutMe,
                style: textStyles.label.copyWith(
                  color: colors.textChat,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: layout.s2),
              MessageMarkdown(
                data: trimmedBio,
                markdownContext: FluxerMarkdownContext.restrictedUserBio,
                baseStyle: textStyles.bodySmall.copyWith(
                  color: colors.textChat,
                  height: 1.35,
                ),
              ),
              SizedBox(height: layout.s4),
            ],
            if (memberSince != null) ...[
              Text(
                l10n.userProfileMemberSince,
                style: textStyles.label.copyWith(
                  color: colors.textChat,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              SizedBox(height: layout.s2),
              Text(
                DateFormat.yMMMd().format(memberSince.toLocal()),
                style: textStyles.bodySmall.copyWith(color: colors.textChat),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
