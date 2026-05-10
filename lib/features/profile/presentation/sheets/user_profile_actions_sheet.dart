import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/features/profile/presentation/sheets/user_profile_confirmation_sheet.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:fluxer_dart/export.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserProfileActionsSheet {
  UserProfileActionsSheet._();

  static Future<void> show(
    BuildContext context,
    WidgetRef ref, {
    required Friend? relationship,
    required UserProfileFullResponseUser user,
    required bool isCurrentUser,
    required Offset position,
    bool hasGuildProfile = false,
    bool isShowingGlobalProfile = false,
    VoidCallback? onShowGlobalProfile,
    VoidCallback? onShowCommunityProfile,
  }) {
    return FluxerActionMenu.show(
      context,
      position: position,
      builder: (menuContext, close) {
        final l10n = FluxerLocalizations.of(menuContext);
        final tag = '${user.username}#${user.discriminator}';
        final status = relationship?.friendStatus;

        return [
          if (hasGuildProfile) ...[
            FluxerMenuItem(
              label: isShowingGlobalProfile
                  ? l10n.userProfileViewCommunityProfile
                  : l10n.userProfileViewMainProfile,
              icon: PhosphorIconsFill.userCircle,
              onPressed: () {
                close();
                if (isShowingGlobalProfile) {
                  onShowCommunityProfile?.call();
                  return;
                }
                onShowGlobalProfile?.call();
              },
            ),
            const FluxerMenuDivider(),
          ],
          FluxerMenuItem(
            label: l10n.userProfileCopyUsername,
            icon: PhosphorIconsFill.copy,
            onPressed: () async {
              close();
              await Clipboard.setData(ClipboardData(text: tag));
            },
          ),
          FluxerMenuItem(
            label: l10n.userProfileCopyUserId,
            icon: PhosphorIconsFill.identificationCard,
            onPressed: () async {
              close();
              await Clipboard.setData(ClipboardData(text: user.id));
            },
          ),
          if (!isCurrentUser) ...[
            const FluxerMenuDivider(),
            if (status == FriendStatus.accepted)
              FluxerMenuItem(
                label: l10n.userProfileRemoveFriend,
                icon: PhosphorIconsFill.userMinus,
                isDanger: true,
                onPressed: () async {
                  close();
                  final ok = await UserProfileConfirmationSheet.show(
                    context,
                    title: l10n.userProfileRemoveFriendConfirmTitle,
                    description: l10n.userProfileRemoveFriendConfirmDescription(
                      user.username,
                    ),
                    primaryLabel: l10n.userProfileRemoveFriend,
                    primaryVariant: FluxerButtonVariant.dangerPrimary,
                  );
                  if (ok) {
                    await _runRepoAction(
                      ref,
                      l10n.userProfileActionFailed,
                      () => ref
                          .read(friendRepositoryProvider)
                          .removeRelationship(user.id),
                    );
                  }
                },
              ),
            if (status == FriendStatus.blocked)
              FluxerMenuItem(
                label: l10n.userProfileUnblockUser,
                icon: PhosphorIconsFill.prohibit,
                onPressed: () async {
                  close();
                  final ok = await UserProfileConfirmationSheet.show(
                    context,
                    title: l10n.userProfileUnblockConfirmTitle,
                    description: l10n.userProfileUnblockConfirmDescription(
                      user.username,
                    ),
                    primaryLabel: l10n.userProfileUnblockUser,
                    primaryVariant: FluxerButtonVariant.primary,
                  );
                  if (ok) {
                    await _runRepoAction(
                      ref,
                      l10n.userProfileActionFailed,
                      () => ref
                          .read(friendRepositoryProvider)
                          .removeRelationship(user.id),
                    );
                  }
                },
              )
            else
              FluxerMenuItem(
                label: l10n.userProfileBlockUser,
                icon: PhosphorIconsFill.prohibit,
                isDanger: true,
                onPressed: () async {
                  close();
                  final ok = await UserProfileConfirmationSheet.show(
                    context,
                    title: l10n.userProfileBlockConfirmTitle,
                    description: l10n.userProfileBlockConfirmDescription(
                      user.username,
                    ),
                    primaryLabel: l10n.userProfileBlockUser,
                    primaryVariant: FluxerButtonVariant.dangerPrimary,
                  );
                  if (ok) {
                    await _runRepoAction(
                      ref,
                      l10n.userProfileActionFailed,
                      () =>
                          ref.read(friendRepositoryProvider).blockUser(user.id),
                    );
                  }
                },
              ),
          ],
        ];
      },
    );
  }

  static Future<void> _runRepoAction(
    WidgetRef ref,
    String errorMessage,
    Future<void> Function() action,
  ) async {
    try {
      await action();
    } on Object catch (e, st) {
      talker.error('[UserProfileActionsSheet] action failed: $e', e, st);
      ref
          .read(toastProvider.notifier)
          .show(
            FluxerToast(
              message: errorMessage,
              variant: FluxerToastVariant.danger,
            ),
          );
    }
  }
}
