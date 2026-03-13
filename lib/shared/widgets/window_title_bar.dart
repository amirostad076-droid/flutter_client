import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:window_manager/window_manager.dart';

/// Height of the custom window title bar.
const kWindowTitleBarHeight = 32.0;

/// A Discord-style thin title bar with window control buttons.
///
/// Provides a [DragToMoveArea] for dragging and double-click to maximize,
/// plus minimize, maximize/restore, and close buttons on the right.
class WindowTitleBar extends StatelessWidget {
  const WindowTitleBar({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onSecondaryTap: windowManager.popUpWindowMenu,
      child: Container(
        height: kWindowTitleBarHeight,
        color: FluxerColors.backgroundPrimary,
        child: Stack(
          children: [
            const DragToMoveArea(child: SizedBox.expand()),
          Positioned(
            top: 0,
            right: 0,
            bottom: 0,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _WindowButton(
                  icon: PhosphorIconsRegular.minus,
                  onPressed: windowManager.minimize,
                ),
                const _MaximizeButton(),
                _WindowButton(
                  icon: PhosphorIconsRegular.x,
                  hoverColor: FluxerColors.textDanger,
                  hoverIconColor: Colors.white,
                  onPressed: windowManager.close,
                ),
              ],
            ),
          ),
          ],
        ),
      ),
    );
  }
}

/// A maximize/restore toggle button that listens to window state changes.
class _MaximizeButton extends StatefulWidget {
  const _MaximizeButton();

  @override
  State<_MaximizeButton> createState() => _MaximizeButtonState();
}

class _MaximizeButtonState extends State<_MaximizeButton> with WindowListener {
  bool _isMaximized = false;

  @override
  void initState() {
    super.initState();
    windowManager.addListener(this);
    unawaited(_queryMaximized());
  }

  @override
  void dispose() {
    windowManager.removeListener(this);
    super.dispose();
  }

  Future<void> _queryMaximized() async {
    final isMaximized = await windowManager.isMaximized();
    if (mounted) {
      setState(() => _isMaximized = isMaximized);
    }
  }

  @override
  void onWindowMaximize() {
    setState(() => _isMaximized = true);
  }

  @override
  void onWindowUnmaximize() {
    setState(() => _isMaximized = false);
  }

  @override
  Widget build(BuildContext context) {
    return _WindowButton(
      icon: _isMaximized
          ? PhosphorIconsRegular.cornersIn
          : PhosphorIconsRegular.square,
      onPressed: () async {
        if (_isMaximized) {
          await windowManager.unmaximize();
        } else {
          await windowManager.maximize();
        }
      },
    );
  }
}

/// A single window-control button with hover state.
class _WindowButton extends StatefulWidget {
  const _WindowButton({
    required this.icon,
    required this.onPressed,
    this.hoverColor,
    this.hoverIconColor,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color? hoverColor;
  final Color? hoverIconColor;

  @override
  State<_WindowButton> createState() => _WindowButtonState();
}

class _WindowButtonState extends State<_WindowButton> {
  bool _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final effectiveHoverColor =
        widget.hoverColor ?? FluxerColors.backgroundModifierHover;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: Container(
          width: 46,
          height: kWindowTitleBarHeight,
          color: _isHovered ? effectiveHoverColor : Colors.transparent,
          child: Center(
            child: PhosphorIcon(
              widget.icon,
              size: 16,
              color: _isHovered && widget.hoverIconColor != null
                  ? widget.hoverIconColor
                  : FluxerColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
