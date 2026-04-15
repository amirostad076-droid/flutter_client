import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/privacy_dashboard_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';

class UserPrivacyDashboard extends ConsumerStatefulWidget {
  const UserPrivacyDashboard({super.key, this.scrollController});

  final ScrollController? scrollController;

  @override
  ConsumerState<UserPrivacyDashboard> createState() =>
      _UserPrivacyDashboardState();
}

class _UserPrivacyDashboardState extends ConsumerState<UserPrivacyDashboard> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(privacyDashboardViewModelProvider);
    final colors = context.colors;
    final layout = context.layout;

    if (state.isLoading) {
      return const Center(child: FluxerLoadingSpinner());
    }

    if (state.error != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              state.error!,
              style: TextStyle(color: colors.textPrimaryMuted),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: layout.s4),
            SizedBox(
              width: double.infinity,
              child: FluxerButton.primary(
                label: 'Retry',
                onPressedAsync: ref
                    .read(privacyDashboardViewModelProvider.notifier)
                    .loadSettings,
              ),
            ),
          ],
        ),
      );
    }

    return SingleChildScrollView(
      controller: widget.scrollController,
      padding: EdgeInsets.all(layout.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConnectionsSection(state, colors, layout),
          _divider(colors),
          _buildCommunicationSection(state, colors, layout),
          _divider(colors),
          _buildSensitiveContentSection(state, colors, layout),
        ],
      ),
    );
  }

  Widget _divider(FluxerColorTheme colors) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 32),
    child: Divider(color: colors.borderColor),
  );

  // ---------------------------------------------------------------------------
  // Connections section
  // ---------------------------------------------------------------------------

  Widget _buildConnectionsSection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerSectionHeading(
          title: 'Connections',
          description:
              'Control who can send you friend requests and direct messages.',
        ),
        SizedBox(height: layout.s4),
        const FluxerFieldLabel('Friend Requests'),
        SizedBox(height: layout.s2),
        FluxerSwitchGroup(
          children: [
            FluxerSwitchGroupItem(
              label: 'Everyone',
              value: state.everyoneCanFriendRequest,
              onChanged: (value) => unawaited(
                ref
                    .read(privacyDashboardViewModelProvider.notifier)
                    .updateFriendSourceFlag(
                      FriendSourceFlag.noRelation,
                      enabled: value,
                    ),
              ),
            ),
            FluxerSwitchGroupItem(
              label: 'Friends of Friends',
              value: state.friendsOfFriendsCanFriend,
              enabled: !state.everyoneCanFriendRequest,
              onChanged: (value) => unawaited(
                ref
                    .read(privacyDashboardViewModelProvider.notifier)
                    .updateFriendSourceFlag(
                      FriendSourceFlag.mutualFriends,
                      enabled: value,
                    ),
              ),
            ),
            FluxerSwitchGroupItem(
              label: 'Community Members',
              value: state.communityMembersCanFriend,
              enabled: !state.everyoneCanFriendRequest,
              onChanged: (value) => unawaited(
                ref
                    .read(privacyDashboardViewModelProvider.notifier)
                    .updateFriendSourceFlag(
                      FriendSourceFlag.mutualGuilds,
                      enabled: value,
                    ),
              ),
            ),
          ],
        ),
        SizedBox(height: layout.s4),
        const FluxerFieldLabel('Direct Messages'),
        SizedBox(height: layout.s2),
        FluxerSwitchGroup(
          children: [
            FluxerSwitchGroupItem(
              label: 'Allow direct messages from community members',
              value: !state.defaultGuildsRestricted,
              onChanged: (value) =>
                  _showDmConfirmationSheet(allowing: value, isBots: false),
            ),
            FluxerSwitchGroupItem(
              label: 'Allow direct messages from community bots',
              value: !state.botDefaultGuildsRestricted,
              onChanged: (value) =>
                  _showDmConfirmationSheet(allowing: value, isBots: true),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _showDmConfirmationSheet({
    required bool allowing,
    required bool isBots,
  }) async {
    final colors = context.colors;
    final layout = context.layout;
    final subject = isBots ? 'bots' : 'members';
    final action = allowing ? 'allow' : 'block';
    final actionCapitalized =
        '${action[0].toUpperCase()}${action.substring(1)}';

    final result = await FluxerBottomSheet.show<bool>(
      context,
      title: '$actionCapitalized DMs from $subject?',
      useRootNavigator: true,
      builder: (sheetContext, close) {
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: layout.s4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Would you like to apply this to all existing communities?',
                style: TextStyle(fontSize: 14, color: colors.textPrimary),
              ),
              SizedBox(height: layout.s2),
              Text(
                'You can also change this on a per-community '
                'basis in community settings.',
                style: TextStyle(fontSize: 13, color: colors.textPrimaryMuted),
              ),
              SizedBox(height: layout.s4),
              SizedBox(
                width: double.infinity,
                child: FluxerButton.primary(
                  label: '$actionCapitalized for all communities',
                  onPressed: () =>
                      Navigator.of(sheetContext, rootNavigator: true).pop(true),
                ),
              ),
              SizedBox(height: layout.s2),
              SizedBox(
                width: double.infinity,
                child: FluxerButton.secondary(
                  label: 'Skip this step',
                  onPressed: () => Navigator.of(
                    sheetContext,
                    rootNavigator: true,
                  ).pop(false),
                ),
              ),
            ],
          ),
        );
      },
    );

    if (result == null) {
      return;
    }

    final vm = ref.read(privacyDashboardViewModelProvider.notifier);
    if (isBots) {
      unawaited(
        vm.updateBotDefaultGuildsRestricted(
          restricted: !allowing,
          applyToAll: result,
        ),
      );
    } else {
      unawaited(
        vm.updateDefaultGuildsRestricted(
          restricted: !allowing,
          applyToAll: result,
        ),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // Communication section
  // ---------------------------------------------------------------------------

  Widget _buildCommunicationSection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerSectionHeading(
          title: 'Communication',
          description: 'Control who can call you and add you to group chats.',
        ),
        SizedBox(height: layout.s4),
        _buildIncomingCallsSubsection(state, colors, layout),
        SizedBox(height: layout.s4),
        _buildGroupDmSubsection(state, colors, layout),
      ],
    );
  }

  Widget _buildIncomingCallsSubsection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    final vm = ref.read(privacyDashboardViewModelProvider.notifier);
    final mode = state.incomingCallMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerFieldLabel('Incoming Calls'),
        SizedBox(height: layout.s2),
        FluxerRadioGroup<PermissionMode>(
          value: mode,
          items: const [
            FluxerRadioItem(value: PermissionMode.nobody, label: 'Nobody'),
            FluxerRadioItem(
              value: PermissionMode.friendsOnly,
              label: 'Friends Only',
              description: 'Recommended',
            ),
            FluxerRadioItem(
              value: PermissionMode.custom,
              label: 'Friends + Custom',
            ),
            FluxerRadioItem(value: PermissionMode.everyone, label: 'Everyone'),
          ],
          onChanged: (newMode) {
            final silentFlag =
                state.incomingCallFlags & IncomingCallFlag.silentEveryone;
            int flags;
            switch (newMode) {
              case PermissionMode.nobody:
                flags = IncomingCallFlag.nobody;
              case PermissionMode.friendsOnly:
                flags = IncomingCallFlag.friendsOnly;
              case PermissionMode.custom:
                flags =
                    IncomingCallFlag.friendsOnly |
                    IncomingCallFlag.friendsOfFriends;
              case PermissionMode.everyone:
                flags = IncomingCallFlag.everyone;
            }
            flags |= silentFlag;
            unawaited(vm.updateIncomingCallFlags(flags));
          },
        ),
        if (mode == PermissionMode.custom) ...[
          SizedBox(height: layout.s3),
          FluxerSwitchGroup(
            children: [
              FluxerSwitchGroupItem(
                label: 'Friends of Friends',
                value: state.callFriendsOfFriends,
                onChanged: (value) {
                  var flags = state.incomingCallFlags;
                  if (value) {
                    flags |= IncomingCallFlag.friendsOfFriends;
                  } else {
                    flags &= ~IncomingCallFlag.friendsOfFriends;
                  }
                  unawaited(vm.updateIncomingCallFlags(flags));
                },
              ),
              FluxerSwitchGroupItem(
                label: 'Community Members',
                value: state.callGuildMembers,
                onChanged: (value) {
                  var flags = state.incomingCallFlags;
                  if (value) {
                    flags |= IncomingCallFlag.guildMembers;
                  } else {
                    flags &= ~IncomingCallFlag.guildMembers;
                  }
                  unawaited(vm.updateIncomingCallFlags(flags));
                },
              ),
            ],
          ),
        ],
        if (mode != PermissionMode.nobody) ...[
          SizedBox(height: layout.s3),
          FluxerSwitchGroupItem(
            label: 'Silent calls from everyone',
            value: state.silentCallsEnabled,
            onChanged: (value) {
              var flags = state.incomingCallFlags;
              if (value) {
                flags |= IncomingCallFlag.silentEveryone;
              } else {
                flags &= ~IncomingCallFlag.silentEveryone;
              }
              unawaited(vm.updateIncomingCallFlags(flags));
            },
          ),
        ],
      ],
    );
  }

  Widget _buildGroupDmSubsection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    final vm = ref.read(privacyDashboardViewModelProvider.notifier);
    final mode = state.groupDmAddMode;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerFieldLabel('Who Can Add You to Group Chats'),
        SizedBox(height: layout.s2),
        FluxerRadioGroup<PermissionMode>(
          value: mode,
          items: const [
            FluxerRadioItem(value: PermissionMode.nobody, label: 'Nobody'),
            FluxerRadioItem(
              value: PermissionMode.friendsOnly,
              label: 'Friends Only',
              description: 'Recommended',
            ),
            FluxerRadioItem(
              value: PermissionMode.custom,
              label: 'Friends + Custom',
            ),
            FluxerRadioItem(value: PermissionMode.everyone, label: 'Everyone'),
          ],
          onChanged: (newMode) {
            int flags;
            switch (newMode) {
              case PermissionMode.nobody:
                flags = GroupDmAddPermissionFlag.nobody;
              case PermissionMode.friendsOnly:
                flags = GroupDmAddPermissionFlag.friendsOnly;
              case PermissionMode.custom:
                flags =
                    GroupDmAddPermissionFlag.friendsOnly |
                    GroupDmAddPermissionFlag.friendsOfFriends;
              case PermissionMode.everyone:
                flags = GroupDmAddPermissionFlag.everyone;
            }
            unawaited(vm.updateGroupDmAddPermissionFlags(flags));
          },
        ),
        if (mode == PermissionMode.custom) ...[
          SizedBox(height: layout.s3),
          FluxerSwitchGroup(
            children: [
              FluxerSwitchGroupItem(
                label: 'Friends of Friends',
                value: state.groupDmFriendsOfFriends,
                onChanged: (value) {
                  var flags = state.groupDmAddPermissionFlags;
                  if (value) {
                    flags |= GroupDmAddPermissionFlag.friendsOfFriends;
                  } else {
                    flags &= ~GroupDmAddPermissionFlag.friendsOfFriends;
                  }
                  unawaited(vm.updateGroupDmAddPermissionFlags(flags));
                },
              ),
              FluxerSwitchGroupItem(
                label: 'Community Members',
                value: state.groupDmGuildMembers,
                onChanged: (value) {
                  var flags = state.groupDmAddPermissionFlags;
                  if (value) {
                    flags |= GroupDmAddPermissionFlag.guildMembers;
                  } else {
                    flags &= ~GroupDmAddPermissionFlag.guildMembers;
                  }
                  unawaited(vm.updateGroupDmAddPermissionFlags(flags));
                },
              ),
            ],
          ),
        ],
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // Sensitive Content section
  // ---------------------------------------------------------------------------

  Widget _buildSensitiveContentSection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    final vm = ref.read(privacyDashboardViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerSectionHeading(
          title: 'Sensitive Content',
          description: 'Control how sensitive media is handled in messages.',
        ),
        SizedBox(height: layout.s4),
        FluxerSelect<int>(
          label: 'Direct messages from friends',
          value: state.effectiveFriendDmFilter,
          enableSearch: false,
          items: const [
            FluxerSelectItem(value: 0, label: 'Show'),
            FluxerSelectItem(value: 1, label: 'Blur'),
            FluxerSelectItem(value: 2, label: 'Block'),
          ],
          onChanged: vm.editFriendDmFilter,
        ),
        SizedBox(height: layout.s4),
        FluxerSelect<int>(
          label: 'Direct messages from others',
          value: state.effectiveNonFriendDmFilter,
          enableSearch: false,
          items: const [
            FluxerSelectItem(value: 0, label: 'Show'),
            FluxerSelectItem(value: 1, label: 'Blur'),
            FluxerSelectItem(value: 2, label: 'Block'),
          ],
          onChanged: vm.editNonFriendDmFilter,
        ),
        SizedBox(height: layout.s4),
        FluxerSelect<int>(
          label: 'Messages in community channels',
          value: state.effectiveGuildFilter,
          enableSearch: false,
          items: const [
            FluxerSelectItem(value: 0, label: 'Show'),
            FluxerSelectItem(value: 1, label: 'Blur'),
          ],
          onChanged: vm.editGuildFilter,
        ),
        SizedBox(height: layout.s4),
        FluxerSwitchGroupItem(
          label: 'Blur media until safety scan completes',
          description: state.isAdult
              ? 'When enabled, images and videos are blurred '
                    'until the content safety scan finishes.'
              : 'This setting is always on for your account.',
          value: !state.isAdult || state.effectiveBlurUnscannedMedia,
          enabled: state.isAdult,
          onChanged: (v) => vm.editBlurUnscannedMedia(value: v),
        ),
        if (state.isSensitiveContentDirty) ...[
          SizedBox(height: layout.s4),
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: FluxerButton.secondary(
                    label: 'Reset',
                    onPressed: vm.resetSensitiveContent,
                  ),
                ),
              ),
              SizedBox(width: layout.s2),
              Expanded(
                child: SizedBox(
                  width: double.infinity,
                  child: FluxerButton.primary(
                    label: 'Save',
                    isLoading: state.isSavingSensitiveContent,
                    onPressedAsync: vm.saveSensitiveContent,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
