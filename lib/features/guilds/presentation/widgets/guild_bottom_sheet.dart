import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/guilds/presentation/'
    'widgets/guild_context_menu.dart';
import 'package:fluxeron/shared/widgets/menu_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<GuildAction?> showGuildBottomSheet(
  BuildContext context, {
  required Guild guild,
  bool hasUnread = false,
  bool isMuted = false,
  bool isOwner = false,
}) async {
  final result = await showStyledBottomSheet<GuildAction>(
    context,
    builder: (context) => _GuildBottomSheet(
      guild: guild,
      hasUnread: hasUnread,
      isMuted: isMuted,
      isOwner: isOwner,
    ),
  );

  if (result == GuildAction.copyGuildId) {
    await Clipboard.setData(ClipboardData(text: guild.id));
  }

  return result;
}

class _GuildBottomSheet extends StatelessWidget {
  final Guild guild;
  final bool hasUnread;
  final bool isMuted;
  final bool isOwner;

  const _GuildBottomSheet({
    required this.guild,
    required this.hasUnread,
    required this.isMuted,
    required this.isOwner,
  });

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    final groups = <Widget>[
      // Group 1: Quick Actions
      MenuGroup(
        children: [
          if (hasUnread)
            MenuItem(
              label: 'Mark as Read',
              icon: PhosphorIconsFill.eye,
              onTap: () => pop(GuildAction.markAsRead),
            ),
          MenuItem(
            label: 'Invite Members',
            icon: PhosphorIconsFill.userPlus,
            onTap: () => pop(GuildAction.inviteMembers),
          ),
          if (isOwner) ...[
            MenuSubmenuItem(
              label: 'Community Settings',
              onTap: () => _openSettingsSheet(context),
            ),
            MenuItem(
              label: 'Create Channel',
              icon: PhosphorIconsFill.plusCircle,
              onTap: () => pop(GuildAction.createChannel),
            ),
            MenuItem(
              label: 'Create Category',
              icon: PhosphorIconsFill.folderPlus,
              onTap: () => pop(GuildAction.createCategory),
            ),
          ],
        ],
      ),

      // Group 2: Preferences
      MenuGroup(
        children: [
          MenuItem(
            label: 'Notification Settings',
            icon: PhosphorIconsFill.bell,
            onTap: () => pop(GuildAction.notificationSettings),
          ),
          MenuItem(
            label: 'Privacy Settings',
            icon: PhosphorIconsFill.shield,
            onTap: () => pop(GuildAction.privacySettings),
          ),
          MenuItem(
            label: 'Edit Community Profile',
            icon: PhosphorIconsFill.userCircle,
            onTap: () => pop(GuildAction.editCommunityProfile),
          ),
        ],
      ),

      // Group 3: Mute & Hide
      MenuGroup(
        children: [
          MenuSubmenuItem(
            label: isMuted ? 'Unmute Community' : 'Mute Community',
            onTap: () => _openMuteSheet(context),
          ),
          MenuCheckboxItem(
            label: 'Hide Muted Channels',
            isChecked: false,
            onTap: () => pop(GuildAction.hideMutedChannels),
          ),
        ],
      ),

      // Group 4: Danger (non-owners only)
      if (!isOwner)
        MenuGroup(
          children: [
            MenuItem(
              label: 'Leave Community',
              icon: PhosphorIconsFill.signOut,
              isDanger: true,
              onTap: () => pop(GuildAction.leaveGuild),
            ),
            MenuItem(
              label: 'Report Community',
              icon: PhosphorIconsFill.flag,
              isDanger: true,
              onTap: () => pop(GuildAction.reportCommunity),
            ),
          ],
        ),

      // Group 5: Utilities
      MenuGroup(
        children: [
          MenuItem(
            label: 'Debug Community',
            icon: PhosphorIconsFill.bug,
            onTap: () => pop(GuildAction.debugCommunity),
          ),
          MenuItem(
            label: 'Copy Community ID',
            icon: PhosphorIconsRegular.snowflake,
            onTap: () => pop(GuildAction.copyGuildId),
          ),
        ],
      ),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              SizedBox(height: layout.s2),
              const BottomSheetDragHandle(),
              SizedBox(height: layout.s3),
              BottomSheetHeader(
                leading: _GuildAvatar(guild: guild),
                title: guild.name,
                subtitle: _GuildStats(guild: guild),
              ),
              SizedBox(height: layout.s3),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    layout.s4,
                    0,
                    layout.s4,
                    layout.s4,
                  ),
                  children: [MenuGroupColumn(children: groups)],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSettingsSheet(BuildContext context) {
    final nav = Navigator.of(context);
    unawaited(
      showStyledBottomSheet<GuildAction>(
        context,
        builder: (_) => const _GuildSettingsSheet(),
      ).then((result) {
        if (result != null) {
          nav.pop(result);
        }
      }),
    );
  }

  void _openMuteSheet(BuildContext context) {
    final nav = Navigator.of(context);
    unawaited(
      showStyledBottomSheet<GuildAction>(
        context,
        builder: (_) => _GuildMuteSheet(isMuted: isMuted),
      ).then((result) {
        if (result != null) {
          nav.pop(result);
        }
      }),
    );
  }
}

class _GuildSettingsSheet extends StatelessWidget {
  const _GuildSettingsSheet();

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.6,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              SizedBox(height: layout.s2),
              const BottomSheetDragHandle(),
              SizedBox(height: layout.s3),
              BottomSheetSubmenuHeader(
                title: 'Community Settings',
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: layout.s3),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    layout.s4,
                    0,
                    layout.s4,
                    layout.s4,
                  ),
                  children: [
                    MenuGroupColumn(
                      children: [
                        MenuGroup(
                          children: [
                            MenuItem(
                              label: 'General',
                              onTap: () => pop(GuildAction.settingsOverview),
                            ),
                            MenuItem(
                              label: 'Roles & Permissions',
                              onTap: () => pop(GuildAction.settingsRoles),
                            ),
                            MenuItem(
                              label: 'Custom Emoji',
                              onTap: () => pop(GuildAction.settingsEmoji),
                            ),
                            MenuItem(
                              label: 'Custom Stickers',
                              onTap: () => pop(GuildAction.settingsStickers),
                            ),
                            MenuItem(
                              label: 'Safety & Moderation',
                              onTap: () =>
                                  pop(GuildAction.settingsSafetyModeration),
                            ),
                            MenuItem(
                              label: 'Activity Log',
                              onTap: () => pop(GuildAction.settingsActivityLog),
                            ),
                            MenuItem(
                              label: 'Webhooks',
                              onTap: () => pop(GuildAction.settingsWebhooks),
                            ),
                            MenuItem(
                              label: 'Custom Invite URL',
                              onTap: () =>
                                  pop(GuildAction.settingsCustomInviteUrl),
                            ),
                            MenuItem(
                              label: 'Discovery',
                              onTap: () => pop(GuildAction.settingsDiscovery),
                            ),
                          ],
                        ),
                        MenuGroup(
                          children: [
                            MenuItem(
                              label: 'Members',
                              onTap: () => pop(GuildAction.settingsMembers),
                            ),
                            MenuItem(
                              label: 'Invite Links',
                              onTap: () => pop(GuildAction.settingsInviteLinks),
                            ),
                            MenuItem(
                              label: 'Bans',
                              onTap: () => pop(GuildAction.settingsBans),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GuildMuteSheet extends StatelessWidget {
  final bool isMuted;

  const _GuildMuteSheet({required this.isMuted});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          child: Column(
            children: [
              SizedBox(height: layout.s2),
              const BottomSheetDragHandle(),
              SizedBox(height: layout.s3),
              BottomSheetSubmenuHeader(
                title: isMuted ? 'Unmute Community' : 'Mute Community',
                onBack: () => Navigator.of(context).pop(),
              ),
              SizedBox(height: layout.s3),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  padding: EdgeInsets.fromLTRB(
                    layout.s4,
                    0,
                    layout.s4,
                    layout.s4,
                  ),
                  children: [
                    MenuGroupColumn(
                      children: [
                        MenuGroup(
                          children: isMuted
                              ? [
                                  MenuItem(
                                    label: 'Unmute Community',
                                    onTap: () => pop(GuildAction.unmute),
                                  ),
                                ]
                              : [
                                  MenuItem(
                                    label: 'For 15 minutes',
                                    onTap: () => pop(GuildAction.mute15Min),
                                  ),
                                  MenuItem(
                                    label: 'For 30 minutes',
                                    onTap: () => pop(GuildAction.mute30Min),
                                  ),
                                  MenuItem(
                                    label: 'For 1 hour',
                                    onTap: () => pop(GuildAction.mute1Hour),
                                  ),
                                  MenuItem(
                                    label: 'For 3 hours',
                                    onTap: () => pop(GuildAction.mute3Hours),
                                  ),
                                  MenuItem(
                                    label: 'For 4 hours',
                                    onTap: () => pop(GuildAction.mute4Hours),
                                  ),
                                  MenuItem(
                                    label: 'For 8 hours',
                                    onTap: () => pop(GuildAction.mute8Hours),
                                  ),
                                  MenuItem(
                                    label: 'For 24 hours',
                                    onTap: () => pop(GuildAction.mute24Hours),
                                  ),
                                  MenuItem(
                                    label: 'For 3 days',
                                    onTap: () => pop(GuildAction.mute3Days),
                                  ),
                                  MenuItem(
                                    label: 'Until I turn it back on',
                                    onTap: () => pop(GuildAction.muteForever),
                                  ),
                                ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Guild-specific widgets
// ---------------------------------------------------------------------------

class _GuildAvatar extends StatelessWidget {
  final Guild guild;

  const _GuildAvatar({required this.guild});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final iconUrl = guild.iconUrl;

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: colors.backgroundSecondaryAlt,
        shape: BoxShape.circle,
      ),
      clipBehavior: Clip.antiAlias,
      child: iconUrl != null
          ? CachedNetworkImage(
              imageUrl: iconUrl,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _buildFallback(context),
            )
          : _buildFallback(context),
    );
  }

  Widget _buildFallback(BuildContext context) {
    return Center(
      child: Text(
        _abbreviation(guild.name),
        style: context.textStyles.label.copyWith(
          color: context.colors.textPrimary,
        ),
      ),
    );
  }

  String _abbreviation(String name) {
    final words = name.split(' ');
    if (words.length >= 2) {
      return '${words[0][0]}${words[1][0]}'.toUpperCase();
    }
    return name.substring(0, name.length.clamp(0, 2)).toUpperCase();
  }
}

class _GuildStats extends StatelessWidget {
  final Guild guild;

  const _GuildStats({required this.guild});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyle = context.textStyles.timestamp;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _StatDot(color: colors.statusOnline),
        const SizedBox(width: 5),
        Text(
          '${guild.onlineCount} Online',
          style: textStyle.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(width: 10),
        _StatDot(color: colors.textTertiarySecondary),
        const SizedBox(width: 5),
        Text(
          '${guild.memberCount} Members',
          style: textStyle.copyWith(color: colors.textTertiary),
        ),
      ],
    );
  }
}

class _StatDot extends StatelessWidget {
  final Color color;

  const _StatDot({required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 8,
      height: 8,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}
