import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_drag_provider.dart';
import 'package:fluxer_app/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/shared/utils/guild_name_abbreviation.dart';
import 'package:gaimon/gaimon.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class GuildDragData {
  const GuildDragData({required this.itemId, required this.isFolder});

  final String itemId;
  final bool isFolder;
}

const Duration _kMobileDropAnimationDuration = Duration(milliseconds: 150);
const double _kGuildIconSize = 48;
const double _kGuildIconInnerSize = 44;
const double _kGuildIconBorderRadius = 15;

class GuildDragFeedback extends StatelessWidget {
  const GuildDragFeedback({
    required this.label,
    this.iconUrl,
    this.isUnavailable = false,
    super.key,
  });

  final String label;
  final String? iconUrl;
  final bool isUnavailable;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final bool hasImage = iconUrl != null && !isUnavailable;
    final Color bgColor = isUnavailable
        ? colors.statusDanger
        : hasImage
        ? Colors.transparent
        : colors.brandPrimary;
    final String initials = abbreviateGuildName(label);
    final int initialsLength = guildNameInitialsLength(label);
    return _FloatingDragIcon(
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(_kGuildIconBorderRadius),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(_kGuildIconBorderRadius),
          child: SizedBox(
            width: _kGuildIconInnerSize,
            height: _kGuildIconInnerSize,
            child: isUnavailable
                ? Center(
                    child: PhosphorIcon(
                      PhosphorIconsRegular.exclamationMark,
                      color: colors.textOnBrandPrimary,
                      size: 28,
                    ),
                  )
                : iconUrl != null
                ? CachedNetworkImage(
                    imageUrl: iconUrl!,
                    fit: BoxFit.cover,
                    errorBuilder: (context, url, error) =>
                        _DragFeedbackInitials(
                          initials: initials,
                          initialsLength: initialsLength,
                          color: colors.textOnBrandPrimary,
                        ),
                  )
                : _DragFeedbackInitials(
                    initials: initials,
                    initialsLength: initialsLength,
                    color: colors.textOnBrandPrimary,
                  ),
          ),
        ),
      ),
    );
  }
}

class GuildFolderDragFeedback extends StatelessWidget {
  const GuildFolderDragFeedback({
    required this.guilds,
    this.folderIcon,
    this.showIconWhenCollapsed = false,
    super.key,
  });

  final List<Guild> guilds;
  final String? folderIcon;
  final bool showIconWhenCollapsed;

  @override
  Widget build(BuildContext context) {
    return _FloatingDragIcon(
      backgroundColor: context.colors.serverIconBackground,
      child: showIconWhenCollapsed && folderIcon != null
          ? Center(
              child: PhosphorIcon(
                _folderIcon(folderIcon),
                color: context.colors.textPrimary,
                size: 24,
              ),
            )
          : _FolderMiniGrid(guilds: guilds),
    );
  }
}

class GuildDragWrapper extends ConsumerWidget {
  const GuildDragWrapper({
    required this.itemId,
    required this.isFolder,
    required this.dragFeedback,
    required this.child,
    this.enabled = true,
    this.allowCombine = true,
    super.key,
  });

  final String itemId;
  final bool isFolder;
  final bool enabled;
  final bool allowCombine;
  final Widget dragFeedback;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final DragState dragState = ref.watch(guildDragProvider);
    final bool isMobile = isMobileLayout(context);
    final Color brandPrimary = context.colors.brandPrimary;
    final DropPosition? dropPosition = dragState.hoverTargetId == itemId
        ? dragState.dropPosition
        : null;

    final Widget dragTarget = DragTarget<GuildDragData>(
      onWillAcceptWithDetails: (details) => details.data.itemId != itemId,
      onMove: (details) => _handleDragMove(
        context: context,
        ref: ref,
        details: details,
        isMobile: isMobile,
      ),
      onLeave: (_) => ref.read(guildDragProvider.notifier).clearHover(),
      onAcceptWithDetails: (details) =>
          _handleDrop(ref: ref, sourceId: details.data.itemId),
      builder: (context, candidateData, rejectedData) {
        return _DragTargetContent(
          dropPosition: dropPosition,
          color: brandPrimary,
          useOutlineIndicators: isMobile,
          child: child,
        );
      },
    );

    if (!enabled) {
      return dragTarget;
    }

    return _GuildDraggable(
      isMobile: isMobile,
      data: GuildDragData(itemId: itemId, isFolder: isFolder),
      feedback: Transform.scale(
        scale: isMobile ? 0.92 : 0.9,
        child: dragFeedback,
      ),
      childWhenDragging: isMobile
          ? const SizedBox.shrink()
          : IgnorePointer(
              child: Visibility(
                visible: false,
                maintainSize: true,
                maintainAnimation: true,
                maintainState: true,
                child: child,
              ),
            ),
      onDragStarted: () {
        if (isMobile) {
          unawaited(HapticFeedback.mediumImpact());
        }
        ref.read(guildDragProvider.notifier).startDrag(itemId);
      },
      onDragEnded: () => ref.read(guildDragProvider.notifier).endDrag(),
      child: dragTarget,
    );
  }

  void _handleDragMove({
    required BuildContext context,
    required WidgetRef ref,
    required DragTargetDetails<GuildDragData> details,
    required bool isMobile,
  }) {
    final RenderBox renderBox = context.findRenderObject()! as RenderBox;
    final double ratio =
        (renderBox.globalToLocal(details.offset).dy / renderBox.size.height)
            .clamp(0.0, 1.0);
    final DragState dragState = ref.read(guildDragProvider);
    final DropPosition? currentPosition = dragState.hoverTargetId == itemId
        ? dragState.dropPosition
        : null;
    final DropPosition position = _resolveDropPosition(
      ratio: ratio,
      sourceIsFolder: details.data.isFolder,
      targetIsFolder: isFolder,
      allowCombine: allowCombine,
      currentPosition: currentPosition,
    );
    final bool didChangeTarget = ref
        .read(guildDragProvider.notifier)
        .updateHover(targetId: itemId, isFolder: isFolder, position: position);
    if (isMobile && didChangeTarget) {
      Gaimon.selection();
    }
  }

  void _handleDrop({required WidgetRef ref, required String sourceId}) {
    final DropPosition? position = ref.read(guildDragProvider).dropPosition;
    if (position == null) {
      return;
    }
    final OrganizedGuildList notifier = ref.read(
      organizedGuildListProvider.notifier,
    );
    switch (position) {
      case DropPosition.before:
        notifier.reorder(
          sourceId: sourceId,
          targetId: itemId,
          insertAfter: false,
        );
      case DropPosition.after:
        notifier.reorder(
          sourceId: sourceId,
          targetId: itemId,
          insertAfter: true,
        );
      case DropPosition.combine:
        if (isFolder) {
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
    }
  }
}

class _GuildDraggable extends StatelessWidget {
  const _GuildDraggable({
    required this.isMobile,
    required this.data,
    required this.feedback,
    required this.childWhenDragging,
    required this.onDragStarted,
    required this.onDragEnded,
    required this.child,
  });

  final bool isMobile;
  final GuildDragData data;
  final Widget feedback;
  final Widget childWhenDragging;
  final VoidCallback onDragStarted;
  final VoidCallback onDragEnded;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (isMobile) {
      return LongPressDraggable<GuildDragData>(
        data: data,
        dragAnchorStrategy: pointerDragAnchorStrategy,
        onDragStarted: onDragStarted,
        onDragEnd: (_) => onDragEnded(),
        onDraggableCanceled: (_, _) => onDragEnded(),
        feedback: feedback,
        childWhenDragging: childWhenDragging,
        child: child,
      );
    }
    return Draggable<GuildDragData>(
      data: data,
      dragAnchorStrategy: pointerDragAnchorStrategy,
      onDragStarted: onDragStarted,
      onDragEnd: (_) => onDragEnded(),
      onDraggableCanceled: (_, _) => onDragEnded(),
      feedback: feedback,
      childWhenDragging: childWhenDragging,
      child: child,
    );
  }
}

class _DragTargetContent extends StatelessWidget {
  const _DragTargetContent({
    required this.dropPosition,
    required this.color,
    required this.useOutlineIndicators,
    required this.child,
  });

  final DropPosition? dropPosition;
  final Color color;
  final bool useOutlineIndicators;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (!useOutlineIndicators) {
      return _DesktopDragTargetContent(
        dropPosition: dropPosition,
        color: color,
        child: child,
      );
    }

    final bool isCombine = dropPosition == DropPosition.combine;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        _AnimatedEdgeSlot(
          isActive: dropPosition == DropPosition.before,
          child: const _DropIndicatorOutlineSlot(),
        ),
        AnimatedScale(
          scale: isCombine ? 0.98 : 1,
          duration: _kMobileDropAnimationDuration,
          curve: Curves.easeOut,
          child: AnimatedContainer(
            duration: _kMobileDropAnimationDuration,
            curve: Curves.easeOut,
            decoration: isCombine
                ? _combineTargetDecoration(color, true)
                : const BoxDecoration(),
            child: child,
          ),
        ),
        _AnimatedEdgeSlot(
          isActive: dropPosition == DropPosition.after,
          child: const _DropIndicatorOutlineSlot(),
        ),
      ],
    );
  }
}

class _AnimatedEdgeSlot extends StatelessWidget {
  const _AnimatedEdgeSlot({required this.isActive, required this.child});

  final bool isActive;
  final Widget child;

  static const Widget _collapsedSlot = SizedBox(
    width: double.infinity,
    height: 0,
  );

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: _kMobileDropAnimationDuration,
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: isActive ? child : _collapsedSlot,
    );
  }
}

class _DesktopDragTargetContent extends StatelessWidget {
  const _DesktopDragTargetContent({
    required this.dropPosition,
    required this.color,
    required this.child,
  });

  final DropPosition? dropPosition;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final bool isCombine = dropPosition == DropPosition.combine;
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (dropPosition == DropPosition.before)
          _DropIndicatorLine(color: color),
        if (isCombine)
          DecoratedBox(
            decoration: _combineTargetDecoration(color, false),
            child: child,
          )
        else
          child,
        if (dropPosition == DropPosition.after)
          _DropIndicatorLine(color: color),
      ],
    );
  }
}

class _FloatingDragIcon extends StatelessWidget {
  const _FloatingDragIcon({required this.child, this.backgroundColor});

  final Widget child;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.35),
      borderRadius: BorderRadius.circular(_kGuildIconBorderRadius),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(_kGuildIconBorderRadius),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SizedBox(
          width: _kGuildIconSize,
          height: _kGuildIconSize,
          child: child,
        ),
      ),
    );
  }
}

class _DragFeedbackInitials extends StatelessWidget {
  const _DragFeedbackInitials({
    required this.initials,
    required this.initialsLength,
    required this.color,
  });

  final String initials;
  final int initialsLength;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        initials,
        style: TextStyle(
          color: color,
          fontSize: _dragFeedbackInitialsFontSize(initialsLength),
          fontWeight: FontWeight.w600,
          height: 1,
        ),
      ),
    );
  }
}

class _FolderMiniGrid extends StatelessWidget {
  const _FolderMiniGrid({required this.guilds});

  final List<Guild> guilds;

  @override
  Widget build(BuildContext context) {
    final List<Guild> gridGuilds = guilds.take(4).toList();
    const double gridPadding = 4;
    const double gridGap = 2;
    return Padding(
      padding: const EdgeInsets.all(gridPadding),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double cellSize = (constraints.maxWidth - gridGap) / 2;
          return Wrap(
            spacing: gridGap,
            runSpacing: gridGap,
            children: [
              for (final Guild guild in gridGuilds)
                SizedBox.square(
                  dimension: cellSize,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(cellSize * 0.3),
                    child: guild.iconUrl != null
                        ? CachedNetworkImage(
                            imageUrl: guild.iconUrl!,
                            fit: BoxFit.cover,
                          )
                        : ColoredBox(
                            color: context.colors.serverIconBackground,
                            child: Center(
                              child: Text(
                                abbreviateGuildName(guild.name, maxLength: 2),
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
          );
        },
      ),
    );
  }
}

class _DropIndicatorOutlineSlot extends StatelessWidget {
  const _DropIndicatorOutlineSlot();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Center(
        child: _DropIndicatorOutline(color: context.colors.brandPrimary),
      ),
    );
  }
}

class _DropIndicatorOutline extends StatelessWidget {
  const _DropIndicatorOutline({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: _kMobileDropAnimationDuration,
      curve: Curves.easeOut,
      width: _kGuildIconSize,
      height: _kGuildIconSize,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(_kGuildIconBorderRadius),
        border: Border.all(color: color.withValues(alpha: 0.85), width: 2),
        color: color.withValues(alpha: 0.08),
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

DropPosition _resolveDropPosition({
  required double ratio,
  required bool sourceIsFolder,
  required bool targetIsFolder,
  required bool allowCombine,
  DropPosition? currentPosition,
}) {
  const double inset = 0.08;

  if (sourceIsFolder || targetIsFolder || !allowCombine) {
    return _resolveSplitDropPosition(
      ratio: ratio,
      split: 0.5,
      currentPosition: currentPosition,
      inset: inset,
    );
  }
  return _resolveSplitDropPosition(
    ratio: ratio,
    split: 0.25,
    upperSplit: 0.75,
    currentPosition: currentPosition,
    inset: inset,
  );
}

DropPosition _resolveSplitDropPosition({
  required double ratio,
  required double split,
  required DropPosition? currentPosition,
  required double inset,
  double? upperSplit,
}) {
  if (upperSplit == null) {
    if (currentPosition == DropPosition.before && ratio < split + inset) {
      return DropPosition.before;
    }
    if (currentPosition == DropPosition.after && ratio > split - inset) {
      return DropPosition.after;
    }
    return ratio < split ? DropPosition.before : DropPosition.after;
  }

  if (currentPosition == DropPosition.before && ratio < split + inset) {
    return DropPosition.before;
  }
  if (currentPosition == DropPosition.combine &&
      ratio > split - inset &&
      ratio < upperSplit + inset) {
    return DropPosition.combine;
  }
  if (currentPosition == DropPosition.after && ratio > upperSplit - inset) {
    return DropPosition.after;
  }
  if (ratio < split) {
    return DropPosition.before;
  }
  if (ratio > upperSplit) {
    return DropPosition.after;
  }
  return DropPosition.combine;
}

BoxDecoration _combineTargetDecoration(Color color, bool isMobile) {
  return BoxDecoration(
    borderRadius: BorderRadius.circular(16),
    border: isMobile
        ? Border.all(color: color.withValues(alpha: 0.9), width: 2)
        : null,
    boxShadow: [
      BoxShadow(
        color: color.withValues(alpha: isMobile ? 0.45 : 0.6),
        blurRadius: isMobile ? 12 : 8,
        spreadRadius: isMobile ? 2 : 1,
      ),
    ],
  );
}

double _dragFeedbackInitialsFontSize(int initialsLength) {
  if (initialsLength <= 2) {
    return 18;
  }
  if (initialsLength <= kGuildIconInitialsMaxLength) {
    return 14;
  }
  return 12;
}

IconData _folderIcon(String? icon) {
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
