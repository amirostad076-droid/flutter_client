import 'dart:async';
import 'dart:math';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxeron/core/constants/assets.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/router/route_state_providers.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/providers/unread_provider.dart';
import 'package:fluxeron/features/friends/providers/friend_providers.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/guilds/presentation/'
    'widgets/guild_bottom_sheet.dart';
import 'package:fluxeron/features/guilds/presentation/'
    'widgets/guild_context_menu.dart';
import 'package:fluxeron/features/guilds/presentation/'
    'widgets/guild_drag_wrapper.dart';
import 'package:fluxeron/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxeron/features/guilds/providers/guild_mute_provider.dart';
import 'package:fluxeron/features/guilds/providers/guild_voice_provider.dart';
import 'package:fluxeron/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:fluxeron/features/settings/providers/user_settings_view_model.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/unread_badge.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuildNavbar extends ConsumerWidget {
  const GuildNavbar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final organizedItems = ref.watch(organizedGuildListProvider);
    final guilds = ref.watch(
      guildListViewModelProvider.select((s) => s.guilds),
    );
    final activeGuildId = ref.watch(activeGuildIdProvider);
    final currentLocation = GoRouterState.of(context).matchedLocation;
    final isDm = currentLocation.startsWith('/channels/@me');
    final isFavorites = currentLocation.startsWith('/channels/@favorites');
    final pendingFriendCount =
        ref.watch(pendingFriendRequestCountProvider).value ?? 0;
    final currentUserId = ref.watch(
      userSettingsViewModelProvider.select((s) => s.userId),
    );
    final unavailableCount = guilds.where((g) => g.isUnavailable).length;

    return Container(
      width: 72,
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondary,
        border: Border(right: BorderSide(color: context.colors.borderColor)),
      ),
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
        child: ListView(
          physics: const BouncingScrollPhysics(),
          padding: EdgeInsets.only(
            top: max(MediaQuery.of(context).padding.top, 4),
            bottom: 8,
          ),
          children: [
            _GuildListItem(
              label: 'Direct Messages',
              isSelected: isDm,
              svgAsset: Assets.fluxerSymbol,
              mentionCount: pendingFriendCount,
              onTap: () {
                context.go(RoutePaths.me);
              },
            ),
            _GuildListItem(
              label: 'Favorites',
              isSelected: isFavorites,
              icon: PhosphorIconsFill.star,
              onTap: () {
                context.go(RoutePaths.favoritesBase);
              },
            ),
            _SidebarDivider(color: context.colors.backgroundModifierHover),
            for (final item in organizedItems)
              switch (item) {
                GuildNavbarGuild(:final guild) => GuildDragWrapper(
                  itemId: guild.id,
                  isFolder: false,
                  enabled: !guild.isUnavailable,
                  child: _buildGuildItem(
                    ref,
                    context,
                    guild: guild,
                    activeGuildId: activeGuildId,
                    currentUserId: currentUserId,
                    unavailableCount: unavailableCount,
                  ),
                ),
                GuildNavbarFolder(:final id) => GuildDragWrapper(
                  itemId: id.toString(),
                  isFolder: true,
                  child: _GuildFolderWidget(
                    folder: item,
                    activeGuildId: activeGuildId,
                    currentUserId: currentUserId,
                    unavailableCount: unavailableCount,
                  ),
                ),
              },
            _SidebarDivider(color: context.colors.backgroundModifierHover),
            _DashedGuildIcon(
              label: 'Add a Server',
              icon: PhosphorIconsRegular.plus,
              onTap: () {},
            ),
            _DashedGuildIcon(
              label: 'Explore Discoverable Servers',
              icon: PhosphorIconsRegular.compass,
              onTap: () {},
            ),
            _DashedGuildIcon(
              label: 'Help',
              icon: PhosphorIconsRegular.question,
              onTap: () {},
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGuildItem(
    WidgetRef ref,
    BuildContext context, {
    required Guild guild,
    required String? activeGuildId,
    required String currentUserId,
    required int unavailableCount,
  }) {
    return Builder(
      builder: (context) {
        final unread = ref.watch(serverUnreadProvider(guild.id)).value;
        final muteState = ref.watch(guildMuteProvider(guild.id)).value;
        final voiceActivity = ref.watch(guildVoiceActivityProvider(guild.id));
        final voiceRows = ref
            .watch(guildVoiceParticipantsProvider(guild.id))
            .value;
        return _GuildListItem(
          label: guild.name,
          guild: guild,
          isSelected: guild.id == activeGuildId,
          isOwner: guild.ownerId == currentUserId,
          iconUrl: guild.iconUrl,
          isUnavailable: guild.isUnavailable,
          unavailableCount: unavailableCount,
          isMuted: muteState?.isMuted ?? false,
          muteEndTime: muteState?.muteEndTime,
          voiceActivity: voiceActivity,
          voiceRows: voiceRows ?? const [],
          hasUnread: !guild.isUnavailable && (unread?.hasUnread ?? false),
          mentionCount: guild.isUnavailable ? 0 : unread?.mentionCount ?? 0,
          onTap: () {
            context.go(RoutePaths.guild(guild.id));
          },
        );
      },
    );
  }
}

class _GuildFolderWidget extends ConsumerStatefulWidget {
  final GuildNavbarFolder folder;
  final String? activeGuildId;
  final String currentUserId;
  final int unavailableCount;

  const _GuildFolderWidget({
    required this.folder,
    required this.activeGuildId,
    required this.currentUserId,
    required this.unavailableCount,
  });

  @override
  ConsumerState<_GuildFolderWidget> createState() => _GuildFolderWidgetState();
}

class _GuildFolderWidgetState extends ConsumerState<_GuildFolderWidget>
    with SingleTickerProviderStateMixin {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final folder = widget.folder;
    final isExpanded = ref.watch(
      folderExpandedStateProvider.select((s) => s.contains(folder.id)),
    );

    // Aggregate unread/mention/voice across all guilds in folder.
    var anyUnread = false;
    var totalMentions = 0;
    var folderVoiceActivity = VoiceActivityType.none;
    for (final guild in folder.guilds) {
      final unread = ref.watch(serverUnreadProvider(guild.id)).value;
      if (!guild.isUnavailable && (unread?.hasUnread ?? false)) {
        anyUnread = true;
      }
      if (!guild.isUnavailable) {
        totalMentions += unread?.mentionCount ?? 0;
      }
      final voiceActivity = ref.watch(guildVoiceActivityProvider(guild.id));
      if (voiceActivity.index > folderVoiceActivity.index) {
        folderVoiceActivity = voiceActivity;
      }
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final folderAccent = folder.color != null && folder.color != 0
        ? Color(folder.color! | 0xFF000000)
        : isDark
        ? context.colors.brandPrimaryLight
        : context.colors.brandPrimary;

    final folderSurface = Color.lerp(
      context.colors.backgroundSecondary,
      folderAccent,
      isDark ? 0.2 : 0.15,
    )!;

    // Stack: background panel behind header + animated guild list.
    // Background spans from header through guild items when expanded.
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.topCenter,
        children: [
          // Background panel (behind everything, spans full height).
          if (isExpanded)
            Positioned.fill(
              child: Center(
                child: Container(
                  width: 48,
                  decoration: BoxDecoration(
                    color: folderSurface,
                    borderRadius: BorderRadius.circular(48 * 0.3),
                  ),
                ),
              ),
            ),
          // Content column: header + animated guild list.
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildFolderButton(
                context,
                folderAccent: folderAccent,
                folderSurface: folderSurface,
                anyUnread: anyUnread,
                totalMentions: totalMentions,
                folderVoiceActivity: folderVoiceActivity,
                isExpanded: isExpanded,
              ),
              // Animated expand/collapse of guild items.
              AnimatedSize(
                duration: const Duration(milliseconds: 200),
                curve: const Cubic(0.25, 0.1, 0.25, 1),
                alignment: Alignment.topCenter,
                child: isExpanded
                    ? Padding(
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            for (final guild in folder.guilds)
                              _buildGuildItemInFolder(context, guild),
                          ],
                        ),
                      )
                    : const SizedBox(width: 72),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFolderButton(
    BuildContext context, {
    required Color folderAccent,
    required Color folderSurface,
    required bool anyUnread,
    required int totalMentions,
    required VoiceActivityType folderVoiceActivity,
    required bool isExpanded,
  }) {
    final folder = widget.folder;
    return Row(
      children: [
        if (!isExpanded)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: const Cubic(0.25, 0.1, 0.25, 1),
            width: 6,
            height: _isHovered
                ? 20
                : anyUnread
                ? 8
                : 0,
            decoration: BoxDecoration(
              color: context.colors.textPrimary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(999),
                bottomRight: Radius.circular(999),
              ),
            ),
          )
        else
          const SizedBox(width: 6),
        const SizedBox(width: 6),
        Stack(
          clipBehavior: Clip.none,
          children: [
            _RightTooltip(
              content: _TooltipLabel(
                label: isExpanded
                    ? 'Collapse ${folder.name ?? _derivedFolderName}'
                    : folder.name ?? _derivedFolderName,
              ),
              child: MouseRegion(
                onEnter: (_) => setState(() => _isHovered = true),
                onExit: (_) => setState(() => _isHovered = false),
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => ref
                      .read(folderExpandedStateProvider.notifier)
                      .toggle(folder.id),
                  child: SizedBox(
                    width: 48,
                    height: 48,
                    child: isExpanded
                        ? Center(
                            child: PhosphorIcon(
                              _folderIcon(folder.icon),
                              color: context.colors.textPrimary,
                              size: 24,
                            ),
                          )
                        : Center(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 70),
                              curve: Curves.easeOut,
                              width: 48,
                              height: 48,
                              decoration: BoxDecoration(
                                color: folderSurface,
                                borderRadius: BorderRadius.circular(48 * 0.3),
                              ),
                              child: _buildFolderContent(context, folderAccent),
                            ),
                          ),
                  ),
                ),
              ),
            ),
            if (!isExpanded && totalMentions > 0)
              Positioned(
                bottom: -4,
                right: -4,
                child: UnreadBadge(mentionCount: totalMentions),
              ),
            if (!isExpanded && folderVoiceActivity != VoiceActivityType.none)
              Positioned(
                top: -4,
                right: -4,
                child: _VoiceActivityBadge(type: folderVoiceActivity),
              ),
          ],
        ),
      ],
    );
  }

  Widget _buildFolderContent(BuildContext context, Color folderAccent) {
    final folder = widget.folder;
    if (folder.showIconWhenCollapsed && folder.icon != null) {
      return Center(
        child: PhosphorIcon(
          _folderIcon(folder.icon),
          color: context.colors.textPrimary,
          size: 24,
        ),
      );
    }

    // 2x2 mini guild icon grid.
    final gridGuilds = folder.guilds.take(4).toList();
    return Padding(
      padding: const EdgeInsets.all(6),
      child: Wrap(
        spacing: 2,
        runSpacing: 2,
        children: [
          for (final guild in gridGuilds)
            SizedBox(
              width: 16,
              height: 16,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16 * 0.3),
                child: guild.iconUrl != null
                    ? CachedNetworkImage(
                        imageUrl: guild.iconUrl!,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        color: context.colors.serverIconBackground,
                        child: Center(
                          child: Text(
                            guild.name.isNotEmpty
                                ? guild.name[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGuildItemInFolder(BuildContext context, Guild guild) {
    return Builder(
      builder: (context) {
        final unread = ref.watch(serverUnreadProvider(guild.id)).value;
        final muteState = ref.watch(guildMuteProvider(guild.id)).value;
        final voiceActivity = ref.watch(guildVoiceActivityProvider(guild.id));
        final voiceRows = ref
            .watch(guildVoiceParticipantsProvider(guild.id))
            .value;
        return GuildDragWrapper(
          itemId: guild.id,
          isFolder: false,
          child: _GuildListItem(
            label: guild.name,
            guild: guild,
            isSelected: guild.id == widget.activeGuildId,
            isOwner: guild.ownerId == widget.currentUserId,
            iconUrl: guild.iconUrl,
            isUnavailable: guild.isUnavailable,
            unavailableCount: widget.unavailableCount,
            isMuted: muteState?.isMuted ?? false,
            muteEndTime: muteState?.muteEndTime,
            voiceActivity: voiceActivity,
            voiceRows: voiceRows ?? const [],
            hasUnread: !guild.isUnavailable && (unread?.hasUnread ?? false),
            mentionCount: guild.isUnavailable ? 0 : unread?.mentionCount ?? 0,
            onTap: () {
              context.go(RoutePaths.guild(guild.id));
            },
          ),
        );
      },
    );
  }

  String get _derivedFolderName {
    final names = widget.folder.guilds.take(3).map((g) => g.name);
    return names.join(', ');
  }

  static IconData _folderIcon(String? icon) {
    return switch (icon) {
      'star' => PhosphorIconsFill.star,
      'heart' => PhosphorIconsFill.heart,
      'bookmark' => PhosphorIconsFill.bookmarkSimple,
      'game_controller' => PhosphorIconsFill.gameController,
      'shield' => PhosphorIconsFill.shield,
      'music_note' => PhosphorIconsFill.musicNote,
      _ => PhosphorIconsFill.folder,
    };
  }
}

class _GuildListItem extends StatefulWidget {
  final String label;
  final Guild? guild;
  final bool isSelected;
  final bool isOwner;
  final bool isUnavailable;
  final int unavailableCount;
  final bool isMuted;
  final DateTime? muteEndTime;
  final VoiceActivityType voiceActivity;
  final List<VoiceParticipantRow> voiceRows;
  final IconData? icon;
  final String? svgAsset;
  final VoidCallback onTap;
  final String? iconUrl;
  final bool hasUnread;
  final int mentionCount;

  const _GuildListItem({
    required this.label,
    required this.onTap,
    this.guild,
    this.isSelected = false,
    this.isOwner = false,
    this.isUnavailable = false,
    this.unavailableCount = 0,
    this.isMuted = false,
    this.muteEndTime,
    this.voiceActivity = VoiceActivityType.none,
    this.voiceRows = const [],
    this.icon,
    this.svgAsset,
    this.iconUrl,
    this.hasUnread = false,
    this.mentionCount = 0,
  });

  @override
  State<_GuildListItem> createState() => _GuildListItemState();
}

class _GuildListItemState extends State<_GuildListItem> {
  var _isHovered = false;

  Widget _buildBackupIcon(BuildContext context, {required bool isActive}) {
    final iconColor = isActive
        ? context.colors.textOnBrandPrimary
        : context.colors.textPrimary;
    return Center(
      child: widget.svgAsset != null
          ? SvgPicture.asset(
              widget.svgAsset!,
              width: 44,
              height: 44,
              colorFilter: ColorFilter.mode(iconColor, BlendMode.srcIn),
            )
          : widget.icon != null
          ? PhosphorIcon(widget.icon!, color: iconColor, size: 32)
          : Text(
              _abbreviation(widget.label),
              style: TextStyle(
                color: iconColor,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isActive = widget.isSelected || _isHovered;
    final borderRadius = isActive ? 13.0 : 22.0;
    final hasImage = widget.iconUrl != null && !widget.isUnavailable;
    final bgColor = widget.isUnavailable
        ? context.colors.statusDanger
        : hasImage
        ? Colors.transparent
        : isActive
        ? context.colors.brandPrimary
        : context.colors.serverIconBackground;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: const Cubic(0.25, 0.1, 0.25, 1),
            width: 6,
            height: widget.isSelected
                ? 40
                : _isHovered
                ? 20
                : widget.hasUnread
                ? 8
                : 0,
            decoration: BoxDecoration(
              color: context.colors.textPrimary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(999),
                bottomRight: Radius.circular(999),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Stack(
            clipBehavior: Clip.none,
            children: [
              _RightTooltip(
                backgroundColor: widget.isUnavailable
                    ? context.colors.statusDanger
                    : null,
                borderColor: widget.isUnavailable
                    ? context.colors.statusDanger
                    : null,
                content: widget.guild != null
                    ? _GuildTooltipContent(
                        guild: widget.guild!,
                        unavailableCount: widget.unavailableCount,
                        isOwner: widget.isOwner,
                        isMuted: widget.isMuted,
                        muteEndTime: widget.muteEndTime,
                        voiceRows: widget.voiceRows,
                      )
                    : _TooltipLabel(label: widget.label),
                child: MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),
                  child: GestureDetector(
                    onTap: widget.onTap,
                    onSecondaryTapUp: widget.guild != null
                        ? (details) => unawaited(
                            _showContextMenu(context, details.globalPosition),
                          )
                        : null,
                    onLongPress: widget.guild != null
                        ? () => unawaited(_showActionSheet(context))
                        : null,
                    child: SizedBox(
                      width: 48,
                      height: 48,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 70),
                          curve: Curves.easeOut,
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: bgColor,
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadiusGeometry.circular(
                              borderRadius,
                            ),
                            child: widget.isUnavailable
                                ? Center(
                                    child: PhosphorIcon(
                                      PhosphorIconsRegular.exclamationMark,
                                      color: context.colors.textOnBrandPrimary,
                                      size: 32,
                                    ),
                                  )
                                : widget.iconUrl != null
                                ? CachedNetworkImage(
                                    imageUrl:
                                        _isHovered &&
                                            widget.guild?.animatedIconUrl !=
                                                null
                                        ? widget.guild!.animatedIconUrl!
                                        : widget.iconUrl!,
                                    errorWidget: (context, url, error) =>
                                        _buildBackupIcon(
                                          context,
                                          isActive: isActive,
                                        ),
                                    progressIndicatorBuilder:
                                        (context, url, progress) =>
                                            _buildBackupIcon(
                                              context,
                                              isActive: isActive,
                                            ),
                                  )
                                : _buildBackupIcon(context, isActive: isActive),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              if (!widget.isUnavailable &&
                  !widget.isSelected &&
                  widget.mentionCount > 0)
                Positioned(
                  bottom: -4,
                  right: -4,
                  child: UnreadBadge(mentionCount: widget.mentionCount),
                ),
              if (!widget.isUnavailable &&
                  widget.voiceActivity != VoiceActivityType.none)
                Positioned(
                  top: -4,
                  right: -4,
                  child: _VoiceActivityBadge(type: widget.voiceActivity),
                ),
            ],
          ),
        ],
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

  Future<void> _showContextMenu(BuildContext context, Offset position) async {
    if (widget.guild == null) {
      return;
    }
    final action = await showGuildContextMenu(
      context,
      position: position,
      guild: widget.guild!,
      hasUnread: widget.hasUnread,
      isOwner: widget.isOwner,
    );
    if (context.mounted && action != null) {
      _handleAction(context, action);
    }
  }

  Future<void> _showActionSheet(BuildContext context) async {
    if (widget.guild == null) {
      return;
    }
    final isMobile = MediaQuery.of(context).size.width < Breakpoints.tablet;
    if (!isMobile) {
      return;
    }
    final action = await showGuildBottomSheet(
      context,
      guild: widget.guild!,
      hasUnread: widget.hasUnread,
      isOwner: widget.isOwner,
    );
    if (context.mounted && action != null) {
      _handleAction(context, action);
    }
  }

  void _handleAction(BuildContext context, GuildAction action) {
    switch (action) {
      case GuildAction.settingsOverview:
      case GuildAction.settingsRoles:
      case GuildAction.settingsEmoji:
      case GuildAction.settingsStickers:
      case GuildAction.settingsSafetyModeration:
      case GuildAction.settingsActivityLog:
      case GuildAction.settingsWebhooks:
      case GuildAction.settingsCustomInviteUrl:
      case GuildAction.settingsDiscovery:
      case GuildAction.settingsMembers:
      case GuildAction.settingsInviteLinks:
      case GuildAction.settingsBans:
        unawaited(context.push(RoutePaths.guildSettingsPath(widget.guild!.id)));
      case GuildAction.copyGuildId:
        break;
      case GuildAction.markAsRead:
      case GuildAction.inviteMembers:
      case GuildAction.createChannel:
      case GuildAction.createCategory:
      case GuildAction.notificationSettings:
      case GuildAction.privacySettings:
      case GuildAction.editCommunityProfile:
      case GuildAction.hideMutedChannels:
      case GuildAction.leaveGuild:
      case GuildAction.reportCommunity:
      case GuildAction.debugCommunity:
      case GuildAction.mute15Min:
      case GuildAction.mute30Min:
      case GuildAction.mute1Hour:
      case GuildAction.mute3Hours:
      case GuildAction.mute4Hours:
      case GuildAction.mute8Hours:
      case GuildAction.mute24Hours:
      case GuildAction.mute3Days:
      case GuildAction.muteForever:
      case GuildAction.unmute:
        break;
    }
  }
}

class _DashedGuildIcon extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;

  const _DashedGuildIcon({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  State<_DashedGuildIcon> createState() => _DashedGuildIconState();
}

class _DashedGuildIconState extends State<_DashedGuildIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _radiusAnim;
  late Animation<Color?> _colorAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 70),
    );
    _radiusAnim = Tween<double>(
      begin: 22,
      end: 13,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _colorAnim = ColorTween(
      begin: context.colors.interactiveMuted,
      end: context.colors.textPrimary,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onEnter() => _controller.forward();

  void _onExit() => _controller.reverse();

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 3),
    child: Row(
      children: [
        const SizedBox(width: 12),
        _RightTooltip(
          content: _TooltipLabel(label: widget.label),
          child: MouseRegion(
            onEnter: (_) => _onEnter(),
            onExit: (_) => _onExit(),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) => SizedBox(
                  width: 48,
                  height: 48,
                  child: Center(
                    child: SizedBox(
                      width: 44,
                      height: 44,
                      child: CustomPaint(
                        painter: _DashedBorderPainter(
                          borderRadius: _radiusAnim.value,
                          color:
                              _colorAnim.value ??
                              context.colors.interactiveMuted,
                        ),
                        child: Center(
                          child: PhosphorIcon(
                            widget.icon,
                            color:
                                _colorAnim.value ??
                                context.colors.interactiveMuted,
                            size: 20,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    ),
  );
}

class _DashedBorderPainter extends CustomPainter {
  final double borderRadius;
  final Color color;

  _DashedBorderPainter({required this.borderRadius, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final rrect = RRect.fromRectAndRadius(
      Offset.zero & size,
      Radius.circular(borderRadius),
    );
    final path = Path()..addRRect(rrect);

    const dashLength = 6.0;
    const gapLength = 4.0;

    final metrics = path.computeMetrics();
    for (final metric in metrics) {
      var distance = 0.0;
      while (distance < metric.length) {
        final end = (distance + dashLength).clamp(0.0, metric.length);
        canvas.drawPath(metric.extractPath(distance, end), paint);
        distance += dashLength + gapLength;
      }
    }
  }

  @override
  bool shouldRepaint(_DashedBorderPainter oldDelegate) =>
      oldDelegate.borderRadius != borderRadius || oldDelegate.color != color;
}

class _RightTooltip extends StatefulWidget {
  final Widget content;
  final Widget child;
  final Color? backgroundColor;
  final Color? borderColor;

  const _RightTooltip({
    required this.content,
    required this.child,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<_RightTooltip> createState() => _RightTooltipState();
}

class _RightTooltipState extends State<_RightTooltip>
    with SingleTickerProviderStateMixin {
  final _layerLink = LayerLink();
  late final AnimationController _animController;
  late final Animation<double> _fadeAnim;
  late final Animation<double> _scaleAnim;
  OverlayEntry? _entry;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeOut);
    _scaleAnim = Tween<double>(
      begin: 0.98,
      end: 1,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
  }

  void _show() {
    if (_entry != null) {
      return;
    }
    final overlay = Overlay.of(context);
    final bgColor = widget.backgroundColor ?? context.colors.backgroundPrimary;
    final borderColor =
        widget.borderColor ?? context.colors.backgroundHeaderSecondary;

    _entry = OverlayEntry(
      builder: (_) => UnconstrainedBox(
        child: CompositedTransformFollower(
          link: _layerLink,
          targetAnchor: Alignment.centerRight,
          followerAnchor: Alignment.centerLeft,
          offset: const Offset(8, 0),
          showWhenUnlinked: false,
          child: IgnorePointer(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                alignment: Alignment.centerLeft,
                child: Material(
                  color: Colors.transparent,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: 350 + _kArrowWidth,
                    ),
                    child: CustomPaint(
                      painter: _TooltipShapePainter(
                        fillColor: bgColor,
                        borderColor: borderColor,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.only(
                          left: _kArrowWidth + 16,
                          right: 16,
                          top: 12,
                          bottom: 12,
                        ),
                        child: widget.content,
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    overlay.insert(_entry!);
    unawaited(_animController.forward());
  }

  void _hide() {
    if (_entry == null) {
      return;
    }
    unawaited(
      _animController.reverse().then((_) {
        _entry?.remove();
        _entry = null;
      }),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _entry?.remove();
    _entry = null;
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => CompositedTransformTarget(
    link: _layerLink,
    child: MouseRegion(
      onEnter: (_) => _show(),
      onExit: (_) => _hide(),
      child: widget.child,
    ),
  );
}

class _SidebarDivider extends StatelessWidget {
  final Color color;

  const _SidebarDivider({required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Center(
        child: Container(
          width: 32,
          height: 2,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(1),
          ),
        ),
      ),
    );
  }
}

class _TooltipLabel extends StatelessWidget {
  final String label;

  const _TooltipLabel({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        color: context.colors.textPrimary,
        fontSize: 16,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _GuildTooltipContent extends StatelessWidget {
  final Guild guild;
  final int unavailableCount;
  final bool isOwner;
  final bool isMuted;
  final DateTime? muteEndTime;
  final List<VoiceParticipantRow> voiceRows;

  const _GuildTooltipContent({
    required this.guild,
    this.unavailableCount = 0,
    this.isOwner = false,
    this.isMuted = false,
    this.muteEndTime,
    this.voiceRows = const [],
  });

  String get _mutedText {
    if (muteEndTime == null) {
      return 'Muted';
    }
    final month = _monthAbbr(muteEndTime!.month);
    final day = muteEndTime!.day;
    final year = muteEndTime!.year;
    final hour = muteEndTime!.hour > 12
        ? muteEndTime!.hour - 12
        : muteEndTime!.hour == 0
        ? 12
        : muteEndTime!.hour;
    final minute = muteEndTime!.minute.toString().padLeft(2, '0');
    final period = muteEndTime!.hour >= 12 ? 'PM' : 'AM';
    return 'Muted until $month $day, $year $hour:$minute $period';
  }

  static String _monthAbbr(int month) => const [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ][month - 1];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: guild.unavailable
          ? Text(
              '$unavailableCount '
              '${unavailableCount == 1 ? 'community is' : 'communities are'}'
              ' temporarily unavailable\n'
              'due to a flux capacitor malfunction.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: context.colors.textPrimary,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            )
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (guild.isPartnered || guild.isVerified) ...[
                      _GuildBadge(isPartnered: guild.isPartnered),
                      const SizedBox(width: 6),
                    ],
                    Flexible(
                      child: Text(
                        guild.name,
                        style: TextStyle(
                          color: context.colors.textPrimary,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
                if (guild.features.contains(
                  'UNAVAILABLE_FOR_EVERYONE_BUT_STAFF',
                )) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Only accessible to Fluxer staff',
                    style: TextStyle(
                      color: context.colors.statusDanger,
                      fontSize: 14,
                    ),
                  ),
                ],
                if (isOwner && guild.features.contains('INVITES_DISABLED')) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Invites are currently paused in this community',
                    style: TextStyle(
                      color: context.colors.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ],
                if (isMuted) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        PhosphorIconsFill.bellSlash,
                        color: context.colors.textSecondary,
                        size: 14,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        _mutedText,
                        style: TextStyle(
                          color: context.colors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ],
                for (final row in voiceRows) ...[
                  const SizedBox(height: 6),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PhosphorIcon(
                        row.isScreenshare
                            ? PhosphorIconsFill.monitor
                            : PhosphorIconsFill.speakerHigh,
                        color: context.colors.textSecondary,
                        size: 28,
                      ),
                      const SizedBox(width: 6),
                      _AvatarStack(avatarUrls: row.avatarUrls),
                    ],
                  ),
                ],
              ],
            ),
    );
  }
}

class _AvatarStack extends StatelessWidget {
  final List<String> avatarUrls;

  const _AvatarStack({required this.avatarUrls});

  @override
  Widget build(BuildContext context) {
    if (avatarUrls.isEmpty) {
      return const SizedBox.shrink();
    }
    return SizedBox(
      width: avatarUrls.length * 20.0 + 8,
      height: 28,
      child: Stack(
        children: [
          for (var i = 0; i < avatarUrls.length; i++)
            Positioned(
              left: i * 20.0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: context.colors.backgroundPrimary,
                    width: 2,
                  ),
                ),
                child: ClipOval(
                  child: CachedNetworkImage(
                    imageUrl: avatarUrls[i],
                    width: 24,
                    height: 24,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _GuildBadge extends StatelessWidget {
  final bool isPartnered;

  const _GuildBadge({required this.isPartnered});

  @override
  Widget build(BuildContext context) {
    if (isPartnered) {
      return Container(
        width: 16,
        height: 16,
        decoration: BoxDecoration(
          color: context.colors.brandPrimary,
          shape: BoxShape.circle,
        ),
        child: Center(
          child: PhosphorIcon(
            PhosphorIconsBold.infinity,
            color: context.colors.textOnBrandPrimary,
            size: 10,
          ),
        ),
      );
    }
    return PhosphorIcon(
      PhosphorIconsFill.sealCheck,
      color: context.colors.textPrimary,
      size: 16,
    );
  }
}

class _VoiceActivityBadge extends StatelessWidget {
  final VoiceActivityType type;

  const _VoiceActivityBadge({required this.type});

  @override
  Widget build(BuildContext context) {
    final IconData icon;
    switch (type) {
      case VoiceActivityType.video:
        icon = PhosphorIconsFill.videoCamera;
      case VoiceActivityType.screenshare:
        icon = PhosphorIconsFill.monitor;
      case VoiceActivityType.voice:
        icon = PhosphorIconsFill.speakerHigh;
      case VoiceActivityType.none:
        return const SizedBox.shrink();
    }
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        color: context.colors.statusOnline,
        shape: BoxShape.circle,
        border: Border.all(
          color: context.colors.serverSidebarBackground,
          width: 3,
        ),
      ),
      child: Center(
        child: PhosphorIcon(
          icon,
          color: context.colors.textOnBrandPrimary,
          size: 12,
        ),
      ),
    );
  }
}

const double _kArrowWidth = 5;
const double _kArrowHeight = 10;
const double _kBorderRadius = 8;

class _TooltipShapePainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;

  _TooltipShapePainter({required this.fillColor, required this.borderColor});

  @override
  void paint(Canvas canvas, Size size) {
    const r = _kBorderRadius;
    const left = _kArrowWidth;
    final centerY = size.height / 2;
    final arrowTop = centerY - _kArrowHeight / 2;
    final arrowBottom = centerY + _kArrowHeight / 2;

    final path = Path()
      // Top-left corner
      ..moveTo(left + r, 0)
      // Top edge → top-right corner
      ..lineTo(size.width - r, 0)
      ..arcToPoint(Offset(size.width, r), radius: const Radius.circular(r))
      // Right edge → bottom-right corner
      ..lineTo(size.width, size.height - r)
      ..arcToPoint(
        Offset(size.width - r, size.height),
        radius: const Radius.circular(r),
      )
      // Bottom edge → bottom-left corner
      ..lineTo(left + r, size.height)
      ..arcToPoint(
        Offset(left, size.height - r),
        radius: const Radius.circular(r),
      )
      // Left edge down to arrow
      ..lineTo(left, arrowBottom)
      // Arrow pointing left
      ..lineTo(0, centerY)
      ..lineTo(left, arrowTop)
      // Left edge up to top-left corner
      ..lineTo(left, r)
      ..arcToPoint(const Offset(left + r, 0), radius: const Radius.circular(r))
      ..close();

    canvas
      ..drawPath(path, Paint()..color = fillColor)
      ..drawPath(
        path,
        Paint()
          ..color = borderColor
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1,
      );
  }

  @override
  bool shouldRepaint(_TooltipShapePainter old) =>
      old.fillColor != fillColor || old.borderColor != borderColor;
}
