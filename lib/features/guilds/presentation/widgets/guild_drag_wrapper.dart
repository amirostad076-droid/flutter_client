import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/guilds/providers/guild_drag_provider.dart';
import 'package:fluxeron/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';

class GuildDragData {
  const GuildDragData({required this.itemId, required this.isFolder});

  final String itemId;
  final bool isFolder;
}

class GuildDragWrapper extends ConsumerWidget {
  const GuildDragWrapper({
    required this.itemId,
    required this.isFolder,
    required this.child,
    super.key,
  });

  final String itemId;
  final bool isFolder;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dragState = ref.watch(guildDragProvider);
    final isHoverTarget = dragState.hoverTargetId == itemId;
    final dropPosition = isHoverTarget ? dragState.dropPosition : null;
    final isMobile = isMobileLayout(context);

    return LongPressDraggable<GuildDragData>(
      data: GuildDragData(itemId: itemId, isFolder: isFolder),
      delay: Duration(milliseconds: isMobile ? 500 : 100),
      onDragStarted: () {
        unawaited(HapticFeedback.mediumImpact());
        ref.read(guildDragProvider.notifier).startDrag(itemId);
      },
      onDragEnd: (_) => ref.read(guildDragProvider.notifier).endDrag(),
      onDraggableCanceled: (velocity, offset) =>
          ref.read(guildDragProvider.notifier).endDrag(),
      feedback: Transform.scale(
        scale: 0.9,
        child: Opacity(
          opacity: 0.8,
          child: Material(color: Colors.transparent, child: child),
        ),
      ),
      childWhenDragging: Opacity(opacity: 0.5, child: child),
      child: DragTarget<GuildDragData>(
        onWillAcceptWithDetails: (details) => details.data.itemId != itemId,
        onMove: (details) {
          final renderBox = context.findRenderObject()! as RenderBox;
          final localOffset = renderBox.globalToLocal(details.offset);
          final height = renderBox.size.height;
          final ratio = (localOffset.dy / height).clamp(0.0, 1.0);

          final sourceIsFolder = details.data.isFolder;
          final DropPosition position;

          if (sourceIsFolder || isFolder) {
            // Folder: only before/after (50/50 split).
            position = ratio < 0.5
                ? DropPosition
                      .before //
                : DropPosition.after;
          } else {
            // Both guilds: before/combine/after.
            if (ratio < 0.25) {
              position = DropPosition.before;
            } else if (ratio > 0.75) {
              position = DropPosition.after;
            } else {
              position = DropPosition.combine;
            }
          }

          ref
              .read(guildDragProvider.notifier)
              .updateHover(
                targetId: itemId,
                isFolder: isFolder,
                position: position,
              );
        },
        onLeave: (_) => ref.read(guildDragProvider.notifier).clearHover(),
        onAcceptWithDetails: (details) {
          final sourceId = details.data.itemId;
          final position = ref.read(guildDragProvider).dropPosition;
          if (position == null) {
            return;
          }

          final notifier = ref.read(organizedGuildListProvider.notifier);

          if (position == DropPosition.before ||
              position == DropPosition.after) {
            notifier.reorder(
              sourceId: sourceId,
              targetId: itemId,
              insertAfter: position == DropPosition.after,
            );
          } else if (isFolder) {
            notifier.moveIntoFolder(
              guildId: sourceId,
              folderId: int.parse(itemId),
            );
          } else {
            notifier.combineIntoFolder(
              sourceGuildId: sourceId,
              targetGuildId: itemId,
            );
          }
        },
        builder: (context, candidateData, rejectedData) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (dropPosition == DropPosition.before)
                _DropIndicatorLine(color: context.colors.brandPrimary),
              if (dropPosition == DropPosition.combine)
                DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: context.colors.brandPrimaryLight.withValues(
                          alpha: 0.6,
                        ),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: child,
                )
              else
                child,
              if (dropPosition == DropPosition.after)
                _DropIndicatorLine(color: context.colors.brandPrimary),
            ],
          );
        },
      ),
    );
  }
}

class _DropIndicatorLine extends StatelessWidget {
  const _DropIndicatorLine({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Container(
        height: 2,
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(1),
        ),
      ),
    );
  }
}
