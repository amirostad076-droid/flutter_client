import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
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

const _kMenuWidth = 220.0;
const _kSubmenuGap = 4.0;

Future<GuildAction?> showGuildContextMenu(
  BuildContext context, {
  required Offset position,
  required Guild guild,
  bool hasUnread = false,
  bool isMuted = false,
  bool isOwner = false,
}) async {
  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) {
    return null;
  }

  final local = overlay.globalToLocal(position);

  final result = await Navigator.of(context).push<GuildAction>(
    _GuildContextMenuRoute(
      position: local,
      overlaySize: overlay.size,
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

class _GuildContextMenuRoute extends PopupRoute<GuildAction> {
  final Offset position;
  final Size overlaySize;
  final Guild guild;
  final bool hasUnread;
  final bool isMuted;
  final bool isOwner;

  _GuildContextMenuRoute({
    required this.position,
    required this.overlaySize,
    required this.guild,
    required this.hasUnread,
    required this.isMuted,
    required this.isOwner,
  });

  @override
  Duration get transitionDuration => const Duration(milliseconds: 120);

  @override
  bool get barrierDismissible => true;

  @override
  Color? get barrierColor => Colors.transparent;

  @override
  String? get barrierLabel => 'Dismiss';

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) => _ContextMenuPage(
    position: position,
    overlaySize: overlaySize,
    animation: animation,
    guild: guild,
    hasUnread: hasUnread,
    isMuted: isMuted,
    isOwner: isOwner,
  );
}

class _ContextMenuPage extends StatefulWidget {
  final Offset position;
  final Size overlaySize;
  final Animation<double> animation;
  final Guild guild;
  final bool hasUnread;
  final bool isMuted;
  final bool isOwner;

  const _ContextMenuPage({
    required this.position,
    required this.overlaySize,
    required this.animation,
    required this.guild,
    required this.hasUnread,
    required this.isMuted,
    required this.isOwner,
  });

  @override
  State<_ContextMenuPage> createState() => _ContextMenuPageState();
}

class _ContextMenuPageState extends State<_ContextMenuPage> {
  String? _activeSubmenuKey;
  final Map<String, GlobalKey> _submenuKeys = {};
  Timer? _hideTimer;
  bool _isSubmenuHovered = false;

  @override
  void dispose() {
    _hideTimer?.cancel();
    super.dispose();
  }

  void _activateSubmenu(String key) {
    _hideTimer?.cancel();
    if (_activeSubmenuKey != key) {
      setState(() => _activeSubmenuKey = key);
    }
  }

  void _requestDeactivate(String key) {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(milliseconds: 100), () {
      if (_activeSubmenuKey == key && !_isSubmenuHovered) {
        setState(() => _activeSubmenuKey = null);
      }
    });
  }

  void _onSubmenuPanelEnter() {
    _hideTimer?.cancel();
    _isSubmenuHovered = true;
  }

  void _onSubmenuPanelExit() {
    _isSubmenuHovered = false;
    if (_activeSubmenuKey != null) {
      _requestDeactivate(_activeSubmenuKey!);
    }
  }

  GlobalKey _keyFor(String submenuKey) {
    return _submenuKeys.putIfAbsent(submenuKey, GlobalKey.new);
  }

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    final mainHeight = _estimateHeight(items);

    final opensLeft =
        widget.position.dx + _kMenuWidth > widget.overlaySize.width - 8;
    final opensUp =
        widget.position.dy + mainHeight > widget.overlaySize.height - 8;

    var mainLeft = opensLeft
        ? widget.position.dx - _kMenuWidth
        : widget.position.dx;
    var mainTop = opensUp
        ? widget.position.dy - mainHeight
        : widget.position.dy;
    mainLeft = mainLeft.clamp(8.0, widget.overlaySize.width - _kMenuWidth - 8);
    mainTop = mainTop.clamp(8.0, widget.overlaySize.height - mainHeight - 8);

    final alignment = Alignment(opensLeft ? 1.0 : -1.0, opensUp ? 1.0 : -1.0);

    Widget? submenuPanel;
    if (_activeSubmenuKey != null) {
      final subKey = _submenuKeys[_activeSubmenuKey];
      if (subKey?.currentContext != null) {
        final subItems = _buildSubmenuItems(context, _activeSubmenuKey!);
        if (subItems.isNotEmpty) {
          final box = subKey!.currentContext!.findRenderObject()! as RenderBox;
          final itemPos = box.localToGlobal(Offset.zero);
          final subHeight = _estimateHeight(subItems);

          final rightX = mainLeft + _kMenuWidth + _kSubmenuGap;
          final leftX = mainLeft - _kMenuWidth - _kSubmenuGap;
          final fitsRight = rightX + _kMenuWidth < widget.overlaySize.width - 8;

          final subLeft = fitsRight ? rightX : leftX;
          final subTop = itemPos.dy.clamp(
            8.0,
            widget.overlaySize.height - subHeight - 8,
          );

          submenuPanel = Positioned(
            left: subLeft,
            top: subTop,
            child: MouseRegion(
              onEnter: (_) => _onSubmenuPanelEnter(),
              onExit: (_) => _onSubmenuPanelExit(),
              child: _MenuPanel(items: subItems),
            ),
          );
        }
      }
    }

    return Stack(
      children: [
        Positioned(
          left: mainLeft,
          top: mainTop,
          child: FadeTransition(
            opacity: CurvedAnimation(
              parent: widget.animation,
              curve: Curves.easeOut,
            ),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(
                  parent: widget.animation,
                  curve: Curves.easeOutCubic,
                ),
              ),
              alignment: alignment,
              child: _MenuPanel(items: items),
            ),
          ),
        ),
        ?submenuPanel,
      ],
    );
  }

  double _estimateHeight(List<Widget> items) {
    var height = 16.0;
    for (final item in items) {
      if (item is _MenuDivider) {
        height += 13;
      } else {
        height += 38;
      }
    }
    return height;
  }

  List<Widget> _buildSubmenuItems(BuildContext context, String key) {
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    return switch (key) {
      'communitySettings' => [
        _MenuItem(
          label: 'General',
          onTap: () => pop(GuildAction.settingsOverview),
        ),
        _MenuItem(
          label: 'Roles & Permissions',
          onTap: () => pop(GuildAction.settingsRoles),
        ),
        _MenuItem(
          label: 'Custom Emoji',
          onTap: () => pop(GuildAction.settingsEmoji),
        ),
        _MenuItem(
          label: 'Custom Stickers',
          onTap: () => pop(GuildAction.settingsStickers),
        ),
        _MenuItem(
          label: 'Safety & Moderation',
          onTap: () => pop(GuildAction.settingsSafetyModeration),
        ),
        _MenuItem(
          label: 'Activity Log',
          onTap: () => pop(GuildAction.settingsActivityLog),
        ),
        _MenuItem(
          label: 'Webhooks',
          onTap: () => pop(GuildAction.settingsWebhooks),
        ),
        _MenuItem(
          label: 'Custom Invite URL',
          onTap: () => pop(GuildAction.settingsCustomInviteUrl),
        ),
        _MenuItem(
          label: 'Discovery',
          onTap: () => pop(GuildAction.settingsDiscovery),
        ),
        const _MenuDivider(),
        _MenuItem(
          label: 'Members',
          onTap: () => pop(GuildAction.settingsMembers),
        ),
        _MenuItem(
          label: 'Invite Links',
          onTap: () => pop(GuildAction.settingsInviteLinks),
        ),
        _MenuItem(label: 'Bans', onTap: () => pop(GuildAction.settingsBans)),
      ],
      'mute' when widget.isMuted => [
        _MenuItem(
          label: 'Unmute Community',
          onTap: () => pop(GuildAction.unmute),
        ),
      ],
      'mute' => [
        _MenuItem(
          label: 'For 15 minutes',
          onTap: () => pop(GuildAction.mute15Min),
        ),
        _MenuItem(
          label: 'For 30 minutes',
          onTap: () => pop(GuildAction.mute30Min),
        ),
        _MenuItem(label: 'For 1 hour', onTap: () => pop(GuildAction.mute1Hour)),
        _MenuItem(
          label: 'For 3 hours',
          onTap: () => pop(GuildAction.mute3Hours),
        ),
        _MenuItem(
          label: 'For 4 hours',
          onTap: () => pop(GuildAction.mute4Hours),
        ),
        _MenuItem(
          label: 'For 8 hours',
          onTap: () => pop(GuildAction.mute8Hours),
        ),
        _MenuItem(
          label: 'For 24 hours',
          onTap: () => pop(GuildAction.mute24Hours),
        ),
        _MenuItem(label: 'For 3 days', onTap: () => pop(GuildAction.mute3Days)),
        _MenuItem(
          label: 'Until I turn it back on',
          onTap: () => pop(GuildAction.muteForever),
        ),
      ],
      _ => [],
    };
  }

  List<Widget> _buildItems(BuildContext context) {
    void pop(GuildAction action) => Navigator.of(context).pop(action);
    final isOwner = widget.isOwner;

    return [
      // Group 1: Quick Actions
      if (widget.hasUnread)
        _MenuItem(
          label: 'Mark as Read',
          icon: PhosphorIconsFill.eye,
          onTap: () => pop(GuildAction.markAsRead),
        ),
      _MenuItem(
        label: 'Invite Members',
        icon: PhosphorIconsFill.userPlus,
        onTap: () => pop(GuildAction.inviteMembers),
      ),
      if (isOwner) ...[
        _SubMenuItem(
          key: _keyFor('communitySettings'),
          label: 'Community Settings',
          isActive: _activeSubmenuKey == 'communitySettings',
          onActivate: () => _activateSubmenu('communitySettings'),
          onDeactivate: () => _requestDeactivate('communitySettings'),
        ),
        _MenuItem(
          label: 'Create Channel',
          icon: PhosphorIconsFill.plusCircle,
          onTap: () => pop(GuildAction.createChannel),
        ),
        _MenuItem(
          label: 'Create Category',
          icon: PhosphorIconsFill.folderPlus,
          onTap: () => pop(GuildAction.createCategory),
        ),
      ],
      const _MenuDivider(),

      // Group 2: Preferences
      _MenuItem(
        label: 'Notification Settings',
        icon: PhosphorIconsFill.bell,
        onTap: () => pop(GuildAction.notificationSettings),
      ),
      _MenuItem(
        label: 'Privacy Settings',
        icon: PhosphorIconsFill.shield,
        onTap: () => pop(GuildAction.privacySettings),
      ),
      _MenuItem(
        label: 'Edit Community Profile',
        icon: PhosphorIconsFill.userCircle,
        onTap: () => pop(GuildAction.editCommunityProfile),
      ),
      const _MenuDivider(),

      // Group 3: Mute & Hide
      _SubMenuItem(
        key: _keyFor('mute'),
        label: widget.isMuted ? 'Unmute Community' : 'Mute Community',
        isActive: _activeSubmenuKey == 'mute',
        onActivate: () => _activateSubmenu('mute'),
        onDeactivate: () => _requestDeactivate('mute'),
      ),
      _CheckboxMenuItem(
        label: 'Hide Muted Channels',
        isChecked: false,
        onTap: () => pop(GuildAction.hideMutedChannels),
      ),
      const _MenuDivider(),

      // Group 4: Danger (non-owners only)
      if (!isOwner) ...[
        _MenuItem(
          label: 'Leave Community',
          icon: PhosphorIconsFill.signOut,
          isDanger: true,
          onTap: () => pop(GuildAction.leaveGuild),
        ),
        _MenuItem(
          label: 'Report Community',
          icon: PhosphorIconsFill.flag,
          isDanger: true,
          onTap: () => pop(GuildAction.reportCommunity),
        ),
        const _MenuDivider(),
      ],

      // Group 5: Debug
      _MenuItem(
        label: 'Debug Community',
        icon: PhosphorIconsFill.bug,
        onTap: () => pop(GuildAction.debugCommunity),
      ),
      const _MenuDivider(),

      // Group 6: Utility
      _MenuItem(
        label: 'Copy Community ID',
        icon: PhosphorIconsRegular.snowflake,
        onTap: () => pop(GuildAction.copyGuildId),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Shared widgets
// ---------------------------------------------------------------------------

class _MenuPanel extends StatelessWidget {
  final List<Widget> items;

  const _MenuPanel({required this.items});

  @override
  Widget build(BuildContext context) {
    final layout = context.layout;
    return Material(
      color: context.colors.backgroundPrimary,
      borderRadius: layout.radiusSm,
      elevation: 8,
      shadowColor: Colors.black45,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: layout.radiusSm,
          border: Border.all(color: context.colors.backgroundModifierAccent),
        ),
        child: SizedBox(
          width: _kMenuWidth,
          child: Padding(
            padding: EdgeInsets.all(layout.s2),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: items,
            ),
          ),
        ),
      ),
    );
  }
}

class _MenuItem extends StatefulWidget {
  final String label;
  final IconData? icon;
  final bool isDanger;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.onTap,
    this.icon,
    this.isDanger = false,
  });

  @override
  State<_MenuItem> createState() => _MenuItemState();
}

class _MenuItemState extends State<_MenuItem> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final Color textColor;
    final Color hoverBg;
    final Color hoverText;

    if (widget.isDanger) {
      textColor = colors.textDanger;
      hoverBg = colors.buttonDangerFill;
      hoverText = colors.buttonDangerText;
    } else {
      textColor = colors.textSecondary;
      hoverBg = colors.backgroundModifierHover;
      hoverText = colors.textPrimary;
    }

    final activeColor = _isHovered ? hoverText : textColor;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: layout.s2),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: _isHovered ? hoverBg : Colors.transparent,
            borderRadius: layout.radiusSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: context.textStyles.label.copyWith(color: activeColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.icon != null) ...[
                SizedBox(width: layout.s3),
                PhosphorIcon(widget.icon!, size: layout.s5, color: activeColor),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _SubMenuItem extends StatefulWidget {
  final String label;
  final bool isActive;
  final VoidCallback onActivate;
  final VoidCallback onDeactivate;

  const _SubMenuItem({
    required this.label,
    required this.isActive,
    required this.onActivate,
    required this.onDeactivate,
    super.key,
  });

  @override
  State<_SubMenuItem> createState() => _SubMenuItemState();
}

class _SubMenuItemState extends State<_SubMenuItem> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final isHighlighted = _isHovered || widget.isActive;

    final textColor = isHighlighted ? colors.textPrimary : colors.textSecondary;
    final bgColor = isHighlighted
        ? colors.backgroundModifierHover
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) {
        setState(() => _isHovered = true);
        widget.onActivate();
      },
      onExit: (_) {
        setState(() => _isHovered = false);
        widget.onDeactivate();
      },
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onActivate,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: layout.s2),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: layout.radiusSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: context.textStyles.label.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: layout.s3),
              PhosphorIcon(
                PhosphorIconsBold.caretRight,
                size: 14,
                color: textColor,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CheckboxMenuItem extends StatefulWidget {
  final String label;
  final bool isChecked;
  final VoidCallback onTap;

  const _CheckboxMenuItem({
    required this.label,
    required this.isChecked,
    required this.onTap,
  });

  @override
  State<_CheckboxMenuItem> createState() => _CheckboxMenuItemState();
}

class _CheckboxMenuItemState extends State<_CheckboxMenuItem> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;
    final textColor = _isHovered ? colors.textPrimary : colors.textSecondary;
    final bgColor = _isHovered
        ? colors.backgroundModifierHover
        : Colors.transparent;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: Container(
          constraints: const BoxConstraints(minHeight: 36),
          padding: EdgeInsets.symmetric(horizontal: 10, vertical: layout.s2),
          margin: const EdgeInsets.symmetric(vertical: 1),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: layout.radiusSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: context.textStyles.label.copyWith(color: textColor),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              SizedBox(width: layout.s3),
              Container(
                width: 18,
                height: 18,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: widget.isChecked
                        ? colors.brandPrimary
                        : colors.interactiveMuted,
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(4),
                  color: widget.isChecked
                      ? colors.brandPrimary
                      : Colors.transparent,
                ),
                child: widget.isChecked
                    ? Center(
                        child: PhosphorIcon(
                          PhosphorIconsBold.check,
                          size: 12,
                          color: colors.textOnBrandPrimary,
                        ),
                      )
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MenuDivider extends StatelessWidget {
  const _MenuDivider();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 1,
      margin: EdgeInsets.symmetric(vertical: context.layout.s1_5),
      color: context.colors.backgroundModifierAccent.withValues(alpha: 0.3),
    );
  }
}
