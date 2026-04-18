import 'dart:async';
import 'dart:io';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/presentation/'
    'widgets/guild_menu_data.dart';
import 'package:fluxer_app/features/ui/ui.dart';

Future<GuildAction?> showGuildBottomSheet(
  BuildContext context, {
  required Guild guild,
  bool hasUnread = false,
  bool isMuted = false,
  bool isOwner = false,
  int permissions = 0,
  DateTime? muteEndTime,
  bool hideMutedChannels = false,
  bool developerMode = false,
}) async {
  final groups = buildGuildMenuGroups(
    hasUnread: hasUnread,
    isMuted: isMuted,
    isOwner: isOwner,
    permissions: permissions,
    muteEndTime: muteEndTime,
    hideMutedChannels: hideMutedChannels,
    developerMode: developerMode,
  );

  final result = await FluxerBottomSheet.show<GuildAction>(
    context,
    builder: (context, _) => _GuildBottomSheet(guild: guild, groups: groups),
  );

  if (result == GuildAction.copyGuildId) {
    await Clipboard.setData(ClipboardData(text: guild.id));
  }

  return result;
}

class _GuildBottomSheet extends StatelessWidget {
  final Guild guild;
  final List<GuildMenuGroup> groups;

  const _GuildBottomSheet({required this.guild, required this.groups});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    final menuGroups = <Widget>[
      for (final group in groups)
        if (group.isNotEmpty)
          FluxerMenuGroup(
            children: [
              for (final entry in group) _buildEntry(context, entry, pop),
            ],
          ),
    ];

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.7,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          bottom: Platform.isAndroid,
          child: Column(
            children: [
              FluxerBottomSheetHeader(
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
                  children: [
                    FluxerBottomSheetGroupColumn(children: menuGroups),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildEntry(
    BuildContext context,
    GuildMenuEntry entry,
    void Function(GuildAction) pop,
  ) {
    return switch (entry) {
      GuildMenuAction() => FluxerBottomSheetMenuItem(
        label: entry.label,
        hint: entry.hint,
        icon: entry.icon,
        isDanger: entry.isDanger,
        onTap: () => pop(entry.action),
      ),
      GuildMenuSubmenu() => FluxerBottomSheetSubmenuItem(
        label: entry.label,
        hint: entry.hint,
        onTap: () => _openSubmenuSheet(context, entry),
      ),
      GuildMenuCheckbox() => FluxerBottomSheetCheckboxItem(
        label: entry.label,
        isChecked: entry.isChecked,
        onTap: () => pop(entry.action),
      ),
    };
  }

  void _openSubmenuSheet(BuildContext context, GuildMenuSubmenu submenu) {
    final nav = Navigator.of(context);
    unawaited(
      FluxerBottomSheet.show<GuildAction>(
        context,
        builder: (_, _) => _GuildSubmenuSheet(submenu: submenu),
      ).then((result) {
        if (result != null) {
          nav.pop(result);
        }
      }),
    );
  }
}

class _GuildSubmenuSheet extends StatelessWidget {
  final GuildMenuSubmenu submenu;

  const _GuildSubmenuSheet({required this.submenu});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    return DraggableScrollableSheet(
      expand: false,
      maxChildSize: 0.85,
      builder: (context, scrollController) {
        return SafeArea(
          bottom: Platform.isAndroid,
          child: Column(
            children: [
              FluxerBottomSheetSubmenuHeader(
                title: submenu.label,
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
                    FluxerBottomSheetGroupColumn(
                      children: [
                        FluxerMenuGroup(
                          children: [
                            for (final entry in submenu.children)
                              if (entry is GuildMenuAction)
                                FluxerBottomSheetMenuItem(
                                  label: entry.label,
                                  icon: entry.icon,
                                  onTap: () => pop(entry.action),
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
