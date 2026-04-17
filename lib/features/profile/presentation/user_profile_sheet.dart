import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/constants/media_proxy_sizes.dart';
import 'package:fluxer_app/core/router/route_names.dart' show RoutePaths;
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart' show fluxerMediaCdn;
import 'package:fluxer_app/features/profile/presentation/sheets/user_profile_actions_sheet.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/user_profile_confirmation_sheet.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/user_profile_note_edit_sheet.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_action_card_row.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_banner.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_bio_card.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_header.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_note_card.dart';
import 'package:fluxer_app/features/profile/presentation/widgets/user_profile_relationship_button.dart';
import 'package:fluxer_app/features/profile/providers/user_note_view_model.dart';
import 'package:fluxer_app/features/profile/providers/user_presence_provider.dart';
import 'package:fluxer_app/features/profile/providers/user_relationship_provider.dart';
import 'package:fluxer_app/features/settings/presentation/user_settings_modal.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_app/shared/providers/user_profile.dart';
import 'package:fluxer_dart/export.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const int _kDefaultAccentColor = 0x4641D9;
const double _kBannerHeight = 184;
const double _kAvatarSize = 80;
const double _kAvatarOverlap = _kAvatarSize / 2;

class FluxerUserProfileSheet {
  FluxerUserProfileSheet._();

  static Future<void> show(
    BuildContext context, {
    required String userId,
    String? guildId,
    bool autoFocusNote = false,
  }) {
    return FluxerBottomSheet.showScrollable<void>(
      context,
      useRootNavigator: true,
      initialChildSize: 0.95,
      minChildSize: 0.5,
      showDragHandle: false,
      disableTopPadding: true,
      builder: (sheetContext, scrollController, close) => _SheetBody(
        userId: userId,
        autoFocusNote: autoFocusNote,
        scrollController: scrollController,
        onClose: close,
      ),
    );
  }
}

class _SheetBody extends ConsumerStatefulWidget {
  const _SheetBody({
    required this.userId,
    required this.autoFocusNote,
    required this.scrollController,
    required this.onClose,
  });

  final String userId;
  final bool autoFocusNote;
  final ScrollController scrollController;
  final VoidCallback onClose;

  @override
  ConsumerState<_SheetBody> createState() => _SheetBodyState();
}

class _SheetBodyState extends ConsumerState<_SheetBody> {
  bool _autoFocusTriggered = false;

  Color _resolveBannerColor(UserProfileFullResponse response) {
    final profile = response.userProfile;
    final candidates = <int?>[
      profile.bannerColor,
      profile.accentColor,
      response.user.avatarColor,
    ];
    for (final candidate in candidates) {
      if (candidate != null) {
        return Color(0xFF000000 | candidate);
      }
    }
    return const Color(0xFF000000 | _kDefaultAccentColor);
  }

  String? _resolveBannerUrl(UserProfileFullResponse response) {
    final banner = response.userProfile.banner;
    if (banner == null) {
      return null;
    }
    final hash = banner.startsWith('a_') ? banner.substring(2) : banner;
    return '$fluxerMediaCdn/banners/${response.user.id}/$hash.webp'
        '?size=${MediaProxySizes.profileBannerModal}';
  }

  Future<void> _handleMessage(
    String userId,
    bool isBlocked,
    String username,
  ) async {
    final l10n = FluxerLocalizations.of(context);
    if (isBlocked) {
      final ok = await UserProfileConfirmationSheet.show(
        context,
        title: l10n.userProfileOpenBlockedDmTitle,
        description: l10n.userProfileOpenBlockedDmDescription(username),
        primaryLabel: l10n.userProfileOpenDm,
        primaryVariant: FluxerButtonVariant.primary,
      );
      if (!ok) {
        return;
      }
    }
    widget.onClose();
    try {
      final channelId = await ref
          .read(dmRepositoryProvider)
          .ensureDmChannel(userId);
      if (!mounted) {
        return;
      }
      context.go(RoutePaths.dmChannel(channelId));
    } on Object {
      if (!mounted) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            FluxerToast(
              message: l10n.userProfileFailedOpenDm,
              variant: FluxerToastVariant.danger,
            ),
          );
    }
  }

  Future<void> _handleRelationshipAction({
    required Future<void> Function() repoCall,
    String? confirmTitle,
    String? confirmDescription,
    String? confirmPrimary,
    FluxerButtonVariant? confirmVariant,
  }) async {
    if (confirmTitle != null) {
      final ok = await UserProfileConfirmationSheet.show(
        context,
        title: confirmTitle,
        description: confirmDescription!,
        primaryLabel: confirmPrimary!,
        primaryVariant: confirmVariant!,
      );
      if (!ok) {
        return;
      }
    }
    try {
      await repoCall();
    } on Object catch (e) {
      if (!mounted) {
        return;
      }
      ref
          .read(toastProvider.notifier)
          .show(
            FluxerToast(
              message: e.toString(),
              variant: FluxerToastVariant.danger,
            ),
          );
    }
  }

  void _maybeAutoFocusNote() {
    if (_autoFocusTriggered || !widget.autoFocusNote) {
      return;
    }
    _autoFocusTriggered = true;
    final initial = ref
        .read(userNoteViewModelProvider(userId: widget.userId))
        .value;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      unawaited(
        UserProfileNoteEditSheet.show(
          context,
          userId: widget.userId,
          initialNote: initial,
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);
    final profileAsync = ref.watch(userProfileProvider(userId: widget.userId));
    final relationshipAsync = ref.watch(
      userRelationshipProvider(userId: widget.userId),
    );
    final presenceAsync = ref.watch(userPresenceProvider(widget.userId));
    final noteAsync = ref.watch(
      userNoteViewModelProvider(userId: widget.userId),
    );
    final ownUserId = ref.watch(userSettingsViewModelProvider).userId;

    _maybeAutoFocusNote();

    return profileAsync.when(
      loading: () => const Center(child: FluxerLoadingSpinner()),
      error: (_, _) => _ErrorState(
        onRetry: () =>
            ref.invalidate(userProfileProvider(userId: widget.userId)),
        message: l10n.userProfileLoadError,
      ),
      data: (response) {
        if (response == null) {
          return _ErrorState(
            onRetry: () =>
                ref.invalidate(userProfileProvider(userId: widget.userId)),
            message: l10n.userProfileLoadError,
          );
        }

        final user = response.user;
        final profile = response.userProfile;
        final relationship = relationshipAsync.value;
        final customStatus = presenceAsync.value?.customStatus;
        final note = noteAsync.value;
        final isBlocked = relationship?.friendStatus == FriendStatus.blocked;
        final isCurrentUser = ownUserId == user.id;

        final bannerColor = _resolveBannerColor(response);
        final bannerUrl = _resolveBannerUrl(response);

        final colors = context.colors;
        final displayName = user.globalName ?? user.username;
        final avatarUrl = user.avatar != null
            ? '$fluxerMediaCdn/avatars/${user.id}/${user.avatar}.png'
            : null;

        return ColoredBox(
          color: colors.backgroundPrimary,
          child: CustomScrollView(
            controller: widget.scrollController,
            slivers: [
              SliverToBoxAdapter(
                child: SizedBox(
                  height: _kBannerHeight + _kAvatarOverlap,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        height: _kBannerHeight,
                        child: ClipRRect(
                          borderRadius: BorderRadius.vertical(
                            top: layout.radiusXxl.topLeft,
                          ),
                          child: UserProfileBanner(
                            bannerUrl: bannerUrl,
                            bannerColor: bannerColor,
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 0,
                        right: 0,
                        child: Padding(
                          padding: EdgeInsets.only(top: layout.s3),
                          child: Center(
                            child: Container(
                              width: 40,
                              height: 4,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.5),
                                borderRadius: BorderRadius.circular(9999),
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        left: layout.s4,
                        top: _kBannerHeight - _kAvatarOverlap,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.backgroundPrimary,
                          ),
                          child: FluxerAvatar.user(
                            fallbackText: displayName,
                            userId: user.id,
                            imageUrl: avatarUrl,
                            avatarColor: user.avatarColor,
                            status: presenceAsync.value?.status,
                            size: _kAvatarSize,
                          ),
                        ),
                      ),
                      Positioned(
                        right: layout.s4,
                        top: _kBannerHeight + layout.s2,
                        child: Row(
                          children: [
                            UserProfileRelationshipButton(
                              relationshipStatus: relationship?.friendStatus,
                              isCurrentUser: isCurrentUser,
                              onUnblock: () => _handleRelationshipAction(
                                repoCall: () => ref
                                    .read(friendRepositoryProvider)
                                    .removeRelationship(user.id),
                                confirmTitle:
                                    l10n.userProfileUnblockConfirmTitle,
                                confirmDescription: l10n
                                    .userProfileUnblockConfirmDescription(
                                      user.username,
                                    ),
                                confirmPrimary: l10n.userProfileUnblockUser,
                                confirmVariant: FluxerButtonVariant.primary,
                              ),
                              onRemoveFriend: () => _handleRelationshipAction(
                                repoCall: () => ref
                                    .read(friendRepositoryProvider)
                                    .removeRelationship(user.id),
                                confirmTitle:
                                    l10n.userProfileRemoveFriendConfirmTitle,
                                confirmDescription: l10n
                                    .userProfileRemoveFriendConfirmDescription(
                                      user.username,
                                    ),
                                confirmPrimary: l10n.userProfileRemoveFriend,
                                confirmVariant:
                                    FluxerButtonVariant.dangerPrimary,
                              ),
                              onAcceptRequest: () => _handleRelationshipAction(
                                repoCall: () => ref
                                    .read(friendRepositoryProvider)
                                    .acceptFriendRequest(user.id),
                              ),
                              onCancelRequest: () => _handleRelationshipAction(
                                repoCall: () => ref
                                    .read(friendRepositoryProvider)
                                    .removeRelationship(user.id),
                              ),
                              onSendFriendRequest: () =>
                                  _handleRelationshipAction(
                                    repoCall: () => ref
                                        .read(friendRepositoryProvider)
                                        .sendFriendRequest(user.id),
                                  ),
                            ),
                            SizedBox(width: layout.s2),
                            _MoreButton(
                              onTap: (position) =>
                                  UserProfileActionsSheet.show(
                                    context,
                                    ref,
                                    relationship: relationship,
                                    user: user,
                                    position: position,
                                  ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SliverPadding(
                padding: EdgeInsets.fromLTRB(
                  layout.s4,
                  layout.s2,
                  layout.s4,
                  layout.s4,
                ),
                sliver: SliverList(
                  delegate: SliverChildListDelegate.fixed([
                    UserProfileHeader(
                      user: user,
                      profile: profile,
                      customStatus: customStatus,
                    ),
                    SizedBox(height: layout.s4),
                    UserProfileActionCardRow(
                      isCurrentUser: isCurrentUser,
                      isBlocked: isBlocked,
                      username: user.username,
                      onMessage: () =>
                          _handleMessage(user.id, isBlocked, user.username),
                      onEditProfile: () => UserSettingsModal.show(
                        context,
                        openProfileSection: true,
                      ),
                    ),
                    SizedBox(height: layout.s4),
                    UserProfileBioCard(bio: profile.bio, userId: user.id),
                    SizedBox(height: layout.s4),
                    UserProfileNoteCard(
                      note: note,
                      onTap: () => UserProfileNoteEditSheet.show(
                        context,
                        userId: user.id,
                        initialNote: note,
                      ),
                    ),
                    SizedBox(height: layout.s4),
                  ]),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MoreButton extends StatefulWidget {
  const _MoreButton({required this.onTap});

  final ValueChanged<Offset> onTap;

  @override
  State<_MoreButton> createState() => _MoreButtonState();
}

class _MoreButtonState extends State<_MoreButton> {
  final GlobalKey _key = GlobalKey();

  void _emit() {
    final renderBox = _key.currentContext?.findRenderObject() as RenderBox?;
    if (renderBox == null) {
      return;
    }
    final pos = renderBox.localToGlobal(Offset(0, renderBox.size.height));
    widget.onTap(pos);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return FluxerTappable(
      key: _key,
      onTap: _emit,
      builder: (context, _) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: PhosphorIcon(
          PhosphorIconsBold.dotsThree,
          size: 20,
          color: colors.textPrimary,
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry, required this.message});

  final VoidCallback onRetry;
  final String message;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final l10n = FluxerLocalizations.of(context);
    return Padding(
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          PhosphorIcon(
            PhosphorIconsFill.prohibit,
            size: 48,
            color: colors.textPrimaryMuted,
          ),
          SizedBox(height: layout.s3),
          Text(
            message,
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: layout.s4),
          FluxerButton.primary(
            label: l10n.userProfileRetry,
            onPressed: onRetry,
          ),
        ],
      ),
    );
  }
}
