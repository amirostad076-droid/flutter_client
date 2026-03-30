import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart'
    show isMobileLayout;
import 'package:fluxer_app/features/ui/action_menu/context_menu_widgets.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum DmNavbarAction {
  markAsRead,
  mute,
  unmute,
  pinDm,
  unpinDm,
  alwaysShow,
  removeAlwaysShow,
  closeDm,
}

Future<DmNavbarAction?> showDmNavbarContextMenu(
  BuildContext context, {
  required Offset position,
  required String channelId,
  required bool hasUnread,
  required bool isMuted,
  required bool isPinned,
  required bool isCollapsed,
  required bool isAllowlisted,
}) async {
  if (isMobileLayout(context)) {
    return _showBottomSheet(
      context,
      hasUnread: hasUnread,
      isMuted: isMuted,
      isPinned: isPinned,
      isCollapsed: isCollapsed,
      isAllowlisted: isAllowlisted,
    );
  }

  final overlay = Overlay.of(context).context.findRenderObject() as RenderBox?;
  if (overlay == null) {
    return null;
  }

  final local = overlay.globalToLocal(position);

  return Navigator.of(context).push<DmNavbarAction>(
    _DmNavbarContextMenuRoute(
      position: local,
      overlaySize: overlay.size,
      hasUnread: hasUnread,
      isMuted: isMuted,
      isPinned: isPinned,
      isCollapsed: isCollapsed,
      isAllowlisted: isAllowlisted,
    ),
  );
}

Future<DmNavbarAction?> _showBottomSheet(
  BuildContext context, {
  required bool hasUnread,
  required bool isMuted,
  required bool isPinned,
  required bool isCollapsed,
  required bool isAllowlisted,
}) {
  return FluxerBottomSheet.show<DmNavbarAction>(
    context,
    builder: (context, close) => Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: FluxerMenuGroup(
        children: _buildBottomSheetItems(
          context: context,
          hasUnread: hasUnread,
          isMuted: isMuted,
          isPinned: isPinned,
          isCollapsed: isCollapsed,
          isAllowlisted: isAllowlisted,
        ),
      ),
    ),
  );
}

List<FluxerBottomSheetMenuItem> _buildBottomSheetItems({
  required BuildContext context,
  required bool hasUnread,
  required bool isMuted,
  required bool isPinned,
  required bool isCollapsed,
  required bool isAllowlisted,
}) {
  void pop(DmNavbarAction action) => Navigator.of(context).pop(action);

  return [
    if (hasUnread)
      FluxerBottomSheetMenuItem(
        icon: PhosphorIconsRegular.checkCircle,
        label: 'Mark as Read',
        onTap: () => pop(DmNavbarAction.markAsRead),
      ),
    FluxerBottomSheetMenuItem(
      icon: isMuted
          ? PhosphorIconsRegular.bell
          : PhosphorIconsRegular.bellSlash,
      label: isMuted ? 'Unmute Conversation' : 'Mute Conversation',
      onTap: () => pop(isMuted ? DmNavbarAction.unmute : DmNavbarAction.mute),
    ),
    FluxerBottomSheetMenuItem(
      icon: PhosphorIconsRegular.pushPin,
      label: isPinned ? 'Unpin DM' : 'Pin DM',
      onTap: () =>
          pop(isPinned ? DmNavbarAction.unpinDm : DmNavbarAction.pinDm),
    ),
    if (isCollapsed)
      FluxerBottomSheetMenuItem(
        icon: isAllowlisted
            ? PhosphorIconsRegular.eyeSlash
            : PhosphorIconsRegular.eye,
        label: isAllowlisted
            ? 'Remove from Always Shown'
            : 'Always Show in Sidebar',
        onTap: () => pop(
          isAllowlisted
              ? DmNavbarAction.removeAlwaysShow
              : DmNavbarAction.alwaysShow,
        ),
      ),
    FluxerBottomSheetMenuItem(
      icon: PhosphorIconsRegular.x,
      label: 'Close DM',
      isDanger: true,
      onTap: () => pop(DmNavbarAction.closeDm),
    ),
  ];
}

class _DmNavbarContextMenuRoute extends PopupRoute<DmNavbarAction> {
  final Offset position;
  final Size overlaySize;
  final bool hasUnread;
  final bool isMuted;
  final bool isPinned;
  final bool isCollapsed;
  final bool isAllowlisted;

  _DmNavbarContextMenuRoute({
    required this.position,
    required this.overlaySize,
    required this.hasUnread,
    required this.isMuted,
    required this.isPinned,
    required this.isCollapsed,
    required this.isAllowlisted,
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
    hasUnread: hasUnread,
    isMuted: isMuted,
    isPinned: isPinned,
    isCollapsed: isCollapsed,
    isAllowlisted: isAllowlisted,
  );
}

class _ContextMenuPage extends StatelessWidget {
  final Offset position;
  final Size overlaySize;
  final Animation<double> animation;
  final bool hasUnread;
  final bool isMuted;
  final bool isPinned;
  final bool isCollapsed;
  final bool isAllowlisted;

  const _ContextMenuPage({
    required this.position,
    required this.overlaySize,
    required this.animation,
    required this.hasUnread,
    required this.isMuted,
    required this.isPinned,
    required this.isCollapsed,
    required this.isAllowlisted,
  });

  @override
  Widget build(BuildContext context) {
    void pop(DmNavbarAction action) => Navigator.of(context).pop(action);

    final items = _buildMenuItems(
      pop: pop,
      hasUnread: hasUnread,
      isMuted: isMuted,
      isPinned: isPinned,
      isCollapsed: isCollapsed,
      isAllowlisted: isAllowlisted,
    );

    final menuHeight = estimateContextMenuHeight(items);
    final opensLeft = position.dx + kContextMenuWidth > overlaySize.width - 8;
    final opensUp = position.dy + menuHeight > overlaySize.height - 8;

    var left = opensLeft ? position.dx - kContextMenuWidth : position.dx;
    var top = opensUp ? position.dy - menuHeight : position.dy;
    left = left.clamp(8.0, overlaySize.width - kContextMenuWidth - 8);
    top = top.clamp(8.0, overlaySize.height - menuHeight - 8);

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
              child: ContextMenuPanel(items: items),
            ),
          ),
        ),
      ],
    );
  }
}

List<Widget> _buildMenuItems({
  required void Function(DmNavbarAction) pop,
  required bool hasUnread,
  required bool isMuted,
  required bool isPinned,
  required bool isCollapsed,
  required bool isAllowlisted,
}) {
  return [
    if (hasUnread)
      ContextMenuItem(
        icon: PhosphorIconsRegular.checkCircle,
        label: 'Mark as Read',
        onTap: () => pop(DmNavbarAction.markAsRead),
      ),
    ContextMenuItem(
      icon: isMuted
          ? PhosphorIconsRegular.bell
          : PhosphorIconsRegular.bellSlash,
      label: isMuted ? 'Unmute Conversation' : 'Mute Conversation',
      onTap: () => pop(isMuted ? DmNavbarAction.unmute : DmNavbarAction.mute),
    ),
    ContextMenuItem(
      icon: PhosphorIconsRegular.pushPin,
      label: isPinned ? 'Unpin DM' : 'Pin DM',
      onTap: () =>
          pop(isPinned ? DmNavbarAction.unpinDm : DmNavbarAction.pinDm),
    ),
    if (isCollapsed)
      ContextMenuItem(
        icon: isAllowlisted
            ? PhosphorIconsRegular.eyeSlash
            : PhosphorIconsRegular.eye,
        label: isAllowlisted
            ? 'Remove from Always Shown'
            : 'Always Show in Sidebar',
        onTap: () => pop(
          isAllowlisted
              ? DmNavbarAction.removeAlwaysShow
              : DmNavbarAction.alwaysShow,
        ),
      ),
    const ContextMenuDivider(),
    ContextMenuItem(
      icon: PhosphorIconsRegular.x,
      label: 'Close DM',
      isDanger: true,
      onTap: () => pop(DmNavbarAction.closeDm),
    ),
  ];
}
