import 'package:flutter/widgets.dart';

import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:intl/intl.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum GuildAction {
  markAsRead,
  inviteMembers,
  createChannel,
  createCategory,
  settingsOverview,
  settingsRoles,
  settingsEmoji,
  settingsStickers,
  settingsSafetyModeration,
  settingsActivityLog,
  settingsWebhooks,
  settingsCustomInviteUrl,
  settingsDiscovery,
  settingsMembers,
  settingsInviteLinks,
  settingsBans,
  notificationSettings,
  privacySettings,
  editCommunityProfile,
  hideMutedChannels,
  leaveGuild,
  reportCommunity,
  reportRaid,
  debugCommunity,
  copyGuildId,
  mute15Min,
  mute30Min,
  mute1Hour,
  mute3Hours,
  mute4Hours,
  mute8Hours,
  mute24Hours,
  mute3Days,
  muteForever,
  unmute,
}

sealed class GuildMenuEntry {
  const GuildMenuEntry();
}

class GuildMenuAction extends GuildMenuEntry {
  final String label;
  final IconData? icon;
  final GuildAction action;
  final bool isDanger;
  final String? hint;

  const GuildMenuAction({
    required this.label,
    required this.action,
    this.icon,
    this.isDanger = false,
    this.hint,
  });
}

class GuildMenuSubmenu extends GuildMenuEntry {
  final String key;
  final String label;
  final String? hint;
  final List<GuildMenuEntry> children;

  const GuildMenuSubmenu({
    required this.key,
    required this.label,
    required this.children,
    this.hint,
  });
}

class GuildMenuCheckbox extends GuildMenuEntry {
  final String label;
  final bool isChecked;
  final GuildAction action;

  const GuildMenuCheckbox({
    required this.label,
    required this.isChecked,
    required this.action,
  });
}

typedef GuildMenuGroup = List<GuildMenuEntry>;

String? _formatMuteHint(DateTime? muteEndTime) {
  if (muteEndTime == null) {
    return 'Muted';
  }
  final now = DateTime.now();
  if (muteEndTime.isBefore(now)) {
    return null;
  }
  return 'Until ${DateFormat.jm().format(muteEndTime)}';
}

List<GuildMenuGroup> buildGuildMenuGroups({
  required bool hasUnread,
  required bool isMuted,
  required bool isOwner,
  required int permissions,
  DateTime? muteEndTime,
  bool hideMutedChannels = false,
  bool developerMode = false,
}) {
  final p = permissions;
  final canInvite = hasPermission(p, Permission.createInstantInvite);
  final canManageChannels = hasPermission(p, Permission.manageChannels);
  final canManageGuild = hasPermission(p, Permission.manageGuild);
  final canAccessSettings =
      canManageGuild ||
      hasPermission(p, Permission.manageRoles) ||
      hasPermission(p, Permission.viewAuditLog) ||
      hasPermission(p, Permission.manageWebhooks) ||
      hasPermission(p, Permission.manageExpressions) ||
      hasPermission(p, Permission.banMembers);

  return <GuildMenuGroup>[
    // Group 1: Quick Actions
    [
      if (hasUnread)
        const GuildMenuAction(
          label: 'Mark as Read',
          icon: PhosphorIconsFill.eye,
          action: GuildAction.markAsRead,
        ),
      if (canInvite)
        const GuildMenuAction(
          label: 'Invite Members',
          icon: PhosphorIconsFill.userPlus,
          action: GuildAction.inviteMembers,
        ),
      if (canAccessSettings)
        GuildMenuSubmenu(
          key: 'communitySettings',
          label: 'Community Settings',
          children: _buildSettingsSubmenu(p),
        ),
      if (canManageChannels) ...[
        const GuildMenuAction(
          label: 'Create Channel',
          icon: PhosphorIconsFill.plusCircle,
          action: GuildAction.createChannel,
        ),
        const GuildMenuAction(
          label: 'Create Category',
          icon: PhosphorIconsFill.folderPlus,
          action: GuildAction.createCategory,
        ),
      ],
      if (canManageGuild)
        const GuildMenuAction(
          label: 'Report Raid',
          icon: PhosphorIconsFill.warning,
          action: GuildAction.reportRaid,
        ),
    ],

    // Group 2: Preferences
    const [
      GuildMenuAction(
        label: 'Notification Settings',
        icon: PhosphorIconsFill.bell,
        action: GuildAction.notificationSettings,
      ),
      GuildMenuAction(
        label: 'Privacy Settings',
        icon: PhosphorIconsFill.shield,
        action: GuildAction.privacySettings,
      ),
      GuildMenuAction(
        label: 'Edit Community Profile',
        icon: PhosphorIconsFill.userCircle,
        action: GuildAction.editCommunityProfile,
      ),
    ],

    // Group 3: Mute & Hide
    [
      if (isMuted)
        GuildMenuAction(
          label: 'Unmute Community',
          icon: PhosphorIconsFill.bellSlash,
          action: GuildAction.unmute,
          hint: _formatMuteHint(muteEndTime),
        )
      else
        const GuildMenuSubmenu(
          key: 'mute',
          label: 'Mute Community',
          children: _muteSubmenuItems,
        ),
      GuildMenuCheckbox(
        label: 'Hide Muted Channels',
        isChecked: hideMutedChannels,
        action: GuildAction.hideMutedChannels,
      ),
    ],

    // Group 4: Danger (non-owners only)
    if (!isOwner)
      const [
        GuildMenuAction(
          label: 'Leave Community',
          icon: PhosphorIconsFill.signOut,
          action: GuildAction.leaveGuild,
          isDanger: true,
        ),
        GuildMenuAction(
          label: 'Report Community',
          icon: PhosphorIconsFill.flag,
          action: GuildAction.reportCommunity,
          isDanger: true,
        ),
      ],

    // Group 5: Debug (developer mode only)
    if (developerMode)
      const [
        GuildMenuAction(
          label: 'Debug Community',
          icon: PhosphorIconsFill.bug,
          action: GuildAction.debugCommunity,
        ),
      ],

    // Group 6: Utility
    const [
      GuildMenuAction(
        label: 'Copy Community ID',
        icon: PhosphorIconsRegular.snowflake,
        action: GuildAction.copyGuildId,
      ),
    ],
  ];
}

typedef _SettingsTab = ({
  String label,
  GuildAction action,
  List<Permission> perms,
});

const _settingsTabDefs = <_SettingsTab>[
  (
    label: 'General',
    action: GuildAction.settingsOverview,
    perms: [Permission.manageGuild],
  ),
  (
    label: 'Roles & Permissions',
    action: GuildAction.settingsRoles,
    perms: [Permission.manageRoles],
  ),
  (
    label: 'Custom Emoji',
    action: GuildAction.settingsEmoji,
    perms: [Permission.createExpressions, Permission.manageExpressions],
  ),
  (
    label: 'Custom Stickers',
    action: GuildAction.settingsStickers,
    perms: [Permission.createExpressions, Permission.manageExpressions],
  ),
  (
    label: 'Safety & Moderation',
    action: GuildAction.settingsSafetyModeration,
    perms: [Permission.manageGuild],
  ),
  (
    label: 'Activity Log',
    action: GuildAction.settingsActivityLog,
    perms: [Permission.viewAuditLog],
  ),
  (
    label: 'Webhooks',
    action: GuildAction.settingsWebhooks,
    perms: [Permission.manageWebhooks],
  ),
  (
    label: 'Custom Invite URL',
    action: GuildAction.settingsCustomInviteUrl,
    perms: [Permission.manageGuild],
  ),
  (
    label: 'Discovery',
    action: GuildAction.settingsDiscovery,
    perms: [Permission.manageGuild],
  ),
  (
    label: 'Members',
    action: GuildAction.settingsMembers,
    perms: [Permission.manageGuild],
  ),
  (
    label: 'Invite Links',
    action: GuildAction.settingsInviteLinks,
    perms: [Permission.manageGuild],
  ),
  (
    label: 'Bans',
    action: GuildAction.settingsBans,
    perms: [Permission.banMembers],
  ),
];

List<GuildMenuEntry> _buildSettingsSubmenu(int permissions) {
  return [
    for (final tab in _settingsTabDefs)
      if (tab.perms.any((p) => hasPermission(permissions, p)))
        GuildMenuAction(label: tab.label, action: tab.action),
  ];
}

const _muteSubmenuItems = <GuildMenuEntry>[
  GuildMenuAction(label: 'For 15 minutes', action: GuildAction.mute15Min),
  GuildMenuAction(label: 'For 30 minutes', action: GuildAction.mute30Min),
  GuildMenuAction(label: 'For 1 hour', action: GuildAction.mute1Hour),
  GuildMenuAction(label: 'For 3 hours', action: GuildAction.mute3Hours),
  GuildMenuAction(label: 'For 4 hours', action: GuildAction.mute4Hours),
  GuildMenuAction(label: 'For 8 hours', action: GuildAction.mute8Hours),
  GuildMenuAction(label: 'For 24 hours', action: GuildAction.mute24Hours),
  GuildMenuAction(label: 'For 3 days', action: GuildAction.mute3Days),
  GuildMenuAction(
    label: 'Until I turn it back on',
    action: GuildAction.muteForever,
  ),
];
