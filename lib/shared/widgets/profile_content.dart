import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_markdown.dart';
import 'package:fluxer_app/features/settings/presentation/user_settings_modal.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/providers/user_profile.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class ProfileContent extends ConsumerWidget {
  final String userId;
  final String displayName;
  final String username;
  final String discriminator;
  final String? avatarUrl;
  final int? avatarColor;

  const ProfileContent({
    required this.userId,
    required this.displayName,
    required this.username,
    required this.discriminator,
    this.avatarUrl,
    this.avatarColor,
    super.key,
  });

  void _editProfile(BuildContext context) {
    unawaited(UserSettingsModal.show(context, openProfileSection: true));
  }

  void _launchSettings(BuildContext context) {
    unawaited(UserSettingsModal.show(context));
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final FluxerColorTheme colors = context.colors;
    final textStyles = context.textStyles;
    final l10n = FluxerLocalizations.of(context);
    final AsyncValue<UserProfileFullResponse?> profileAsync = ref.watch(
      userProfileProvider(userId: userId),
    );

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ColoredBox(
            color: colors.brandPrimary,
            child: SizedBox(
              height: 88 + MediaQuery.of(context).padding.top,
              width: double.infinity,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(right: 12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: colors.backgroundPrimary,
                            width: 4,
                          ),
                        ),
                        child: FluxerAvatar.user(
                          fallbackText: displayName,
                          userId: userId,
                          imageUrl: avatarUrl,
                          avatarColor: avatarColor,
                          size: 88,
                        ),
                      ),
                      const Spacer(),
                      FluxerButton.circle(
                        icon: PhosphorIconsFill.gear,
                        variant: FluxerButtonVariant.secondary,
                        size: FluxerButtonSize.compact,
                        onPressed: () => _launchSettings(context),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        displayName,
                        style: textStyles.heading.copyWith(
                          color: colors.textChat,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              '$username'
                              '#$discriminator',
                              style: textStyles.label.copyWith(
                                color: colors.textPrimaryMuted,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),
                  FluxerButton.primary(
                    onPressed: () => _editProfile(context),
                    icon: PhosphorIconsDuotone.pencilSimple,
                    label: l10n.profileEditButton,
                  ),
                  const SizedBox(height: 20),
                  _ProfileCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.aboutMeLabel,
                          style: textStyles.label.copyWith(
                            color: colors.textChat,
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        profileAsync.when(
                          data: (UserProfileFullResponse? response) {
                            final String? raw = response?.userProfile.bio
                                ?.trim();
                            if (raw == null || raw.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            return MessageMarkdown(
                              data: raw,
                              markdownContext:
                                  FluxerMarkdownContext.restrictedUserBio,
                              baseStyle: textStyles.bodySmall.copyWith(
                                color: colors.textChat,
                                height: 1.35,
                              ),
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                        const SizedBox(height: 20),
                        profileAsync.when(
                          data: (UserProfileFullResponse? response) {
                            final String snowflakeId =
                                response?.user.id ?? userId;
                            if (snowflakeId.isEmpty) {
                              return const SizedBox.shrink();
                            }
                            final DateTime memberSince =
                                dateTimeFromUserSnowflakeOrNull(snowflakeId) ??
                                DateTime.fromMillisecondsSinceEpoch(
                                  kSnowflakeEpochMs,
                                  isUtc: true,
                                );
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  l10n.profilePreviewMemberSince,
                                  style: TextStyle(
                                    color: colors.textChat,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  DateFormat.yMMMd().format(
                                    memberSince.toLocal(),
                                  ),
                                  style: textStyles.bodySmall.copyWith(
                                    color: colors.textChat,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            );
                          },
                          loading: () => const SizedBox.shrink(),
                          error: (_, _) => const SizedBox.shrink(),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  _ProfileCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    l10n.profileNoteLabel,
                                    style: TextStyle(
                                      color: colors.textChat,
                                      fontSize: 15,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    l10n.profileNoteVisibility,
                                    style: textStyles.timestamp,
                                  ),
                                ],
                              ),
                            ),
                            FluxerButton.circle(
                              onPressed: () => _editProfile(context),
                              icon: PhosphorIconsRegular.pencilSimple,
                              variant: FluxerButtonVariant.secondary,
                              size: FluxerButtonSize.compact,
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        _SelfNoteText(userId: userId),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SelfNoteText extends ConsumerWidget {
  final String userId;

  const _SelfNoteText({required this.userId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (userId.isEmpty) {
      return const SizedBox.shrink();
    }
    final noteStyle = context.textStyles.bodySmall.copyWith(height: 1.35);
    return ref
        .watch(userProfileSelfNoteProvider(userId: userId))
        .when(
          data: (String? note) => Text(
            note ?? FluxerLocalizations.of(context).profileNoteEmpty,
            style: noteStyle,
          ),
          loading: () => const SizedBox.shrink(),
          error: (_, _) => const SizedBox.shrink(),
        );
  }
}

class _ProfileCard extends StatelessWidget {
  final Widget child;

  const _ProfileCard({required this.child});

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(padding: const EdgeInsets.all(16), child: child),
    );
  }
}
