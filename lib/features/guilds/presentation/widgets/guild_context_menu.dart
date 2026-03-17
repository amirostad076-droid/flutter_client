import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum GuildAction { markAsRead, muteToggle, copyGuildId, leaveGuild }

const _kMenuWidth = 220.0;

Future<GuildAction?> showGuildContextMenu(
  BuildContext context, {
  required Offset position,
  required Guild guild,
  bool hasUnread = false,
  bool isMuted = false,
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

  _GuildContextMenuRoute({
    required this.position,
    required this.overlaySize,
    required this.guild,
    required this.hasUnread,
    required this.isMuted,
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
  );
}

class _ContextMenuPage extends StatelessWidget {
  final Offset position;
  final Size overlaySize;
  final Animation<double> animation;
  final Guild guild;
  final bool hasUnread;
  final bool isMuted;

  const _ContextMenuPage({
    required this.position,
    required this.overlaySize,
    required this.animation,
    required this.guild,
    required this.hasUnread,
    required this.isMuted,
  });

  @override
  Widget build(BuildContext context) {
    final items = _buildItems(context);
    final estimatedHeight = _estimateHeight(items);

    final opensLeft = position.dx + _kMenuWidth > overlaySize.width - 8;
    final opensUp = position.dy + estimatedHeight > overlaySize.height - 8;

    var left = opensLeft ? position.dx - _kMenuWidth : position.dx;
    var top = opensUp ? position.dy - estimatedHeight : position.dy;
    if (left < 8) {
      left = 8;
    }
    if (top < 8) {
      top = 8;
    }

    final alignment = Alignment(opensLeft ? 1.0 : -1.0, opensUp ? 1.0 : -1.0);

    return Stack(
      children: [
        Positioned(
          left: left,
          top: top,
          child: FadeTransition(
            opacity: CurvedAnimation(parent: animation, curve: Curves.easeOut),
            child: ScaleTransition(
              scale: Tween<double>(begin: 0.92, end: 1).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
              ),
              alignment: alignment,
              child: _MenuPanel(items: items),
            ),
          ),
        ),
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

  List<Widget> _buildItems(BuildContext context) {
    void pop(GuildAction action) => Navigator.of(context).pop(action);

    return [
      if (hasUnread)
        _MenuItem(
          label: 'Mark as Read',
          icon: PhosphorIconsRegular.envelopeOpen,
          onTap: () => pop(GuildAction.markAsRead),
        ),
      if (hasUnread) const _MenuDivider(),
      _MenuItem(
        label: isMuted ? 'Unmute Community' : 'Mute Community',
        icon: isMuted
            ? PhosphorIconsRegular.bellRinging
            : PhosphorIconsRegular.bellSlash,
        onTap: () => pop(GuildAction.muteToggle),
      ),
      const _MenuDivider(),
      _MenuItem(
        label: 'Leave Community',
        icon: PhosphorIconsRegular.signOut,
        isDanger: true,
        onTap: () => pop(GuildAction.leaveGuild),
      ),
      const _MenuDivider(),
      _MenuItem(
        label: 'Copy Community ID',
        icon: PhosphorIconsRegular.hash,
        onTap: () => pop(GuildAction.copyGuildId),
      ),
    ];
  }
}

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
  final IconData icon;
  final bool isDanger;
  final VoidCallback onTap;

  const _MenuItem({
    required this.label,
    required this.icon,
    required this.onTap,
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
              SizedBox(width: layout.s3),
              PhosphorIcon(widget.icon, size: layout.s5, color: activeColor),
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
