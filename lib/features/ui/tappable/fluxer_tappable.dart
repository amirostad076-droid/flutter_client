import 'package:flutter/material.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

typedef FluxerTappableBuilder =
    Widget Function(BuildContext context, Set<WidgetState> states);

class FluxerTappable extends StatefulWidget {
  const FluxerTappable({
    required this.builder,
    this.onTap,
    this.onLongPress,
    this.enabled = true,
    this.semanticLabel,
    this.hitTestBehavior = HitTestBehavior.opaque,
    super.key,
  });

  final FluxerTappableBuilder builder;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final bool enabled;
  final String? semanticLabel;
  final HitTestBehavior hitTestBehavior;

  @override
  State<FluxerTappable> createState() => _FluxerTappableState();
}

class _FluxerTappableState extends State<FluxerTappable> {
  bool _isHovered = false;
  bool _isPressed = false;
  bool _isFocused = false;

  Set<WidgetState> get _states => {
    if (!widget.enabled) WidgetState.disabled,
    if (_isHovered && widget.enabled) WidgetState.hovered,
    if (_isPressed && widget.enabled) WidgetState.pressed,
    if (_isFocused && widget.enabled) WidgetState.focused,
  };

  void _handleTapDown(TapDownDetails _) {
    if (!widget.enabled) {
      return;
    }
    setState(() => _isPressed = true);
  }

  void _handleTapUp(TapUpDetails _) {
    setState(() => _isPressed = false);
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
  }

  @override
  Widget build(BuildContext context) {
    final motion = context.motion;

    return Semantics(
      label: widget.semanticLabel,
      button: widget.onTap != null,
      enabled: widget.enabled,
      child: MouseRegion(
        cursor: widget.enabled
            ? SystemMouseCursors.click
            : SystemMouseCursors.basic,
        onEnter: (_) => setState(() => _isHovered = true),
        onExit: (_) {
          setState(() {
            _isHovered = false;
            _isPressed = false;
          });
        },
        child: Focus(
          onFocusChange: (focused) => setState(() => _isFocused = focused),
          child: GestureDetector(
            behavior: widget.hitTestBehavior,
            onTap: widget.enabled ? widget.onTap : null,
            onLongPress: widget.enabled ? widget.onLongPress : null,
            onTapDown: _handleTapDown,
            onTapUp: _handleTapUp,
            onTapCancel: _handleTapCancel,
            child: AnimatedOpacity(
              opacity: _isPressed ? 0.7 : (widget.enabled ? 1.0 : 0.5),
              duration: _isPressed
                  ? Duration(milliseconds: motion.fast.inMilliseconds ~/ 2)
                  : motion.fast,
              curve: motion.curve,
              child: widget.builder(context, _states),
            ),
          ),
        ),
      ),
    );
  }
}
