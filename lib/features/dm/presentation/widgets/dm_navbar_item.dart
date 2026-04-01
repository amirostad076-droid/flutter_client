import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:go_router/go_router.dart';

class DmNavbarItem extends ConsumerStatefulWidget {
  final String channelId;
  final String recipientId;
  final String displayName;
  final String? avatarUrl;
  final int? avatarColor;
  final int type;
  final int mentionCount;
  final bool isSelected;
  final void Function(Offset position)? onContextMenu;

  const DmNavbarItem({
    required this.channelId,
    required this.recipientId,
    required this.displayName,
    required this.type,
    this.avatarUrl,
    this.avatarColor,
    this.mentionCount = 0,
    this.isSelected = false,
    this.onContextMenu,
    super.key,
  });

  @override
  ConsumerState<DmNavbarItem> createState() => _DmNavbarItemState();
}

class _DmNavbarItemState extends ConsumerState<DmNavbarItem> {
  bool _isHovered = false;

  bool get _hasUnread => widget.mentionCount > 0;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    final indicatorHeight = widget.isSelected
        ? 40.0
        : _isHovered
        ? 20.0
        : _hasUnread
        ? 8.0
        : 0.0;

    final borderRadius = (widget.isSelected || _isHovered) ? 13.0 : 22.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOutCubic,
            width: 6,
            height: indicatorHeight,
            decoration: BoxDecoration(
              color: colors.textPrimary,
              borderRadius: const BorderRadius.only(
                topRight: Radius.circular(4),
                bottomRight: Radius.circular(4),
              ),
            ),
          ),
          const SizedBox(width: 6),
          FluxerTooltip(
            message: widget.displayName,
            position: FluxerTooltipPosition.right,
            child: MouseRegion(
              onEnter: (_) => setState(() => _isHovered = true),
              onExit: (_) => setState(() => _isHovered = false),
              child: GestureDetector(
                onTap: () => context.go('/channels/@me/${widget.channelId}'),
                onSecondaryTapDown: (details) =>
                    widget.onContextMenu?.call(details.globalPosition),
                onLongPress: () => widget.onContextMenu?.call(Offset.zero),
                child: SizedBox(
                  width: 48,
                  height: 48,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          curve: Curves.easeOutCubic,
                          width: 44,
                          height: 44,
                          clipBehavior: Clip.antiAlias,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(borderRadius),
                          ),
                          child: widget.type == 3
                              ? FluxerAvatarCluster(
                                  channelId: widget.channelId,
                                  size: 44,
                                )
                              : FluxerAvatar.user(
                                  fallbackText: widget.displayName,
                                  userId: widget.recipientId,
                                  imageUrl: widget.avatarUrl,
                                  avatarColor: widget.avatarColor,
                                  size: 44,
                                ),
                        ),
                      ),
                      if (widget.mentionCount > 0 && !widget.isSelected)
                        Positioned(
                          bottom: -4,
                          right: -4,
                          child: FluxerBadge.count(count: widget.mentionCount),
                        ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
