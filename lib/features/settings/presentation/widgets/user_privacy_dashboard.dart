import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/privacy_dashboard_view_model.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/features/ui/warning_alert/fluxer_warning_alert.dart';

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
          _divider(colors),
          _buildDataExportSection(state, colors, layout),
          _divider(colors),
          _buildDataDeletionSection(state, colors, layout),
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

  // ---------------------------------------------------------------------------
  // Data Export section
  // ---------------------------------------------------------------------------

  Widget _buildDataExportSection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerSectionHeading(
          title: 'Data Export',
          description: 'Download a complete package of your account data.',
        ),
        SizedBox(height: layout.s4),
        Text(
          'You can choose to include:',
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimary,
          ),
        ),
        SizedBox(height: layout.s2),
        _bulletPoint(
          colors,
          'Account',
          'profile, settings, relationships, payments, '
              'and all account metadata',
        ),
        SizedBox(height: layout.s1),
        _bulletPoint(
          colors,
          'Messages',
          "all messages you've sent, with channel context and attachment URLs",
        ),
        SizedBox(height: layout.s1),
        _bulletPoint(
          colors,
          'Communities',
          "basic metadata about communities you're in",
        ),
        SizedBox(height: layout.s1),
        _bulletPoint(
          colors,
          'Analytics',
          'all analytics events associated with your activity',
        ),
        SizedBox(height: layout.s4),
        const FluxerWarningAlert(
          message:
              "You can request a data export once every 7 days. You'll "
              'receive an email with a download link valid for 7 days.',
          variant: FluxerAlertVariant.info,
        ),
        SizedBox(height: layout.s4),
        SizedBox(
          width: double.infinity,
          child: FluxerButton.primary(
            label: 'Request Data Export',
            onPressed: _showDataExportSheet,
          ),
        ),
      ],
    );
  }

  void _showDataExportSheet() {
    final colors = context.colors;
    final layout = context.layout;

    unawaited(
      FluxerBottomSheet.showScrollable<void>(
        context,
        title: 'Request Data Export',
        useRootNavigator: true,
        builder: (sheetContext, scrollController, close) {
          return _DataExportSheetContent(
            scrollController: scrollController,
            initialSelected: const {'account', 'messages', 'communities'},
            colors: colors,
            layout: layout,
            onRequest: (categories) async {
              final vm = ref.read(privacyDashboardViewModelProvider.notifier);
              await vm.requestDataExport(categories);
              close();
            },
            onCancel: close,
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Data Deletion section
  // ---------------------------------------------------------------------------

  Widget _buildDataDeletionSection(
    PrivacyDashboardViewState state,
    FluxerColorTheme colors,
    FluxerLayoutTheme layout,
  ) {
    final vm = ref.read(privacyDashboardViewModelProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FluxerSectionHeading(
          title: 'Data Deletion',
          description: 'Permanently delete all messages you have sent.',
        ),
        if (state.hasPendingDeletion) ...[
          SizedBox(height: layout.s4),
          FluxerWarningAlert(
            message:
                'Deletion will remove ${state.pendingDeletion!.messageCount} '
                'messages from '
                '${state.pendingDeletion!.channelCount} channels. '
                'Scheduled to run on '
                '${_formatScheduledDate(state.pendingDeletion!.scheduledAt)}.',
          ),
          SizedBox(height: layout.s3),
          SizedBox(
            width: double.infinity,
            child: FluxerButton.secondary(
              label: 'Cancel pending deletion',
              onPressedAsync: vm.cancelBulkMessageDeletion,
            ),
          ),
        ],
        SizedBox(height: layout.s4),
        Text(
          'Once deleted, your messages cannot be recovered. The deletion '
          'process runs in the background and may take some time depending '
          'on how many messages you have sent.',
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimaryMuted,
          ),
        ),
        SizedBox(height: layout.s4),
        SizedBox(
          width: double.infinity,
          child: FluxerButton.dangerPrimary(
            label: 'Delete all my messages',
            onPressed: state.hasPendingDeletion
                ? null
                : _showDeleteMessagesSheet,
          ),
        ),
      ],
    );
  }

  void _showDeleteMessagesSheet() {
    final colors = context.colors;
    final layout = context.layout;

    unawaited(
      FluxerBottomSheet.show<void>(
        context,
        title: 'Delete All Messages',
        useRootNavigator: true,
        builder: (sheetContext, close) {
          return Padding(
            padding: EdgeInsets.symmetric(horizontal: layout.s4),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Are you sure you want to delete all your messages? '
                  'This action cannot be undone.',
                  style: context.textStyles.bodySmall.copyWith(
                    color: colors.textPrimary,
                  ),
                ),
                SizedBox(height: layout.s4),
                Text(
                  'What happens next:',
                  style: context.textStyles.bodyMedium.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: layout.s2),
                _numberedStep(
                  colors,
                  1,
                  'Your deletion request will be queued and processed '
                  'in the background',
                ),
                SizedBox(height: layout.s1),
                _numberedStep(
                  colors,
                  2,
                  'The job starts 24 hours after you confirm and can be '
                  'canceled or restarted anytime',
                ),
                SizedBox(height: layout.s1),
                _numberedStep(
                  colors,
                  3,
                  'The time to complete depends on how many messages '
                  'you have sent',
                ),
                SizedBox(height: layout.s1),
                _numberedStep(
                  colors,
                  4,
                  'Once deleted, your messages cannot be recovered',
                ),
                SizedBox(height: layout.s4),
                SizedBox(
                  width: double.infinity,
                  child: FluxerButton.dangerPrimary(
                    label: 'Delete All Messages',
                    onPressedAsync: () async {
                      final vm = ref.read(
                        privacyDashboardViewModelProvider.notifier,
                      );
                      await vm.requestBulkMessageDeletion();
                      close();
                    },
                  ),
                ),
                SizedBox(height: layout.s2),
                SizedBox(
                  width: double.infinity,
                  child: FluxerButton.secondary(
                    label: 'Cancel',
                    onPressed: close,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Helpers
  // ---------------------------------------------------------------------------

  Widget _bulletPoint(FluxerColorTheme colors, String title, String detail) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '\u2022 ',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: title,
                    style: context.textStyles.bodySmall.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  TextSpan(
                    text: ' \u2013 $detail',
                    style: context.textStyles.bodySmall.copyWith(
                      color: colors.textPrimaryMuted,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _numberedStep(FluxerColorTheme colors, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatScheduledDate(String isoDate) {
    final dt = DateTime.parse(isoDate).toLocal();
    final year = dt.year.toString();
    final month = dt.month.toString().padLeft(2, '0');
    final day = dt.day.toString().padLeft(2, '0');
    final hour = dt.hour.toString().padLeft(2, '0');
    final minute = dt.minute.toString().padLeft(2, '0');
    return '$year-$month-$day $hour:$minute';
  }
}

// ---------------------------------------------------------------------------
// Data Export sheet content (extracted to manage local checkbox state)
// ---------------------------------------------------------------------------

class _DataExportSheetContent extends StatefulWidget {
  const _DataExportSheetContent({
    required this.scrollController,
    required this.initialSelected,
    required this.colors,
    required this.layout,
    required this.onRequest,
    required this.onCancel,
  });

  final ScrollController scrollController;
  final Set<String> initialSelected;
  final FluxerColorTheme colors;
  final FluxerLayoutTheme layout;
  final Future<void> Function(Set<String> categories) onRequest;
  final VoidCallback onCancel;

  @override
  State<_DataExportSheetContent> createState() =>
      _DataExportSheetContentState();
}

class _DataExportSheetContentState extends State<_DataExportSheetContent> {
  late final Set<String> _selected;

  @override
  void initState() {
    super.initState();
    _selected = Set<String>.from(widget.initialSelected);
  }

  void _toggle(String category) {
    setState(() {
      if (_selected.contains(category)) {
        _selected.remove(category);
      } else {
        _selected.add(category);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return ListView(
      controller: widget.scrollController,
      padding: EdgeInsets.symmetric(horizontal: layout.s4),
      children: [
        Text(
          'Select which categories of data to include in your export.',
          style: context.textStyles.bodySmall.copyWith(
            color: colors.textPrimaryMuted,
          ),
        ),
        SizedBox(height: layout.s4),
        FluxerCheckbox(
          value: _selected.contains('account'),
          onChanged: (_) => _toggle('account'),
          child: Text(
            'Account \u2013 profile, settings, relationships, payments',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: layout.s3),
        FluxerCheckbox(
          value: _selected.contains('messages'),
          onChanged: (_) => _toggle('messages'),
          child: Text(
            'Messages \u2013 all messages with channel context',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: layout.s3),
        FluxerCheckbox(
          value: _selected.contains('communities'),
          onChanged: (_) => _toggle('communities'),
          child: Text(
            'Communities \u2013 basic community metadata',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: layout.s3),
        FluxerCheckbox(
          value: _selected.contains('analytics'),
          onChanged: (_) => _toggle('analytics'),
          child: Text(
            'Analytics \u2013 activity events and usage data',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ),
        SizedBox(height: layout.s4),
        Text(
          'What happens next:',
          style: context.textStyles.bodyMedium.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w600,
          ),
        ),
        SizedBox(height: layout.s2),
        _buildStep(colors, 1, 'Your export request will be queued'),
        SizedBox(height: layout.s1),
        _buildStep(colors, 2, 'Data is compiled in the background'),
        SizedBox(height: layout.s1),
        _buildStep(colors, 3, "You'll receive an email when it's ready"),
        SizedBox(height: layout.s1),
        _buildStep(colors, 4, 'The download link is valid for 7 days'),
        SizedBox(height: layout.s4),
        SizedBox(
          width: double.infinity,
          child: FluxerButton.primary(
            label: 'Request Export',
            onPressedAsync: _selected.isEmpty
                ? null
                : () => widget.onRequest(_selected),
          ),
        ),
        SizedBox(height: layout.s2),
        SizedBox(
          width: double.infinity,
          child: FluxerButton.secondary(
            label: 'Cancel',
            onPressed: widget.onCancel,
          ),
        ),
      ],
    );
  }

  Widget _buildStep(FluxerColorTheme colors, int number, String text) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$number. ',
            style: context.textStyles.bodySmall.copyWith(
              color: colors.textPrimaryMuted,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: context.textStyles.bodySmall.copyWith(
                color: colors.textPrimaryMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
