import 'dart:async';

import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';

class SpoilerOverlay extends StatefulWidget {
  const SpoilerOverlay({
    required this.child,
    required this.isSpoiler,
    required this.initiallyRevealed,
    super.key,
  });

  final Widget child;
  final bool isSpoiler;
  final bool initiallyRevealed;

  @override
  State<SpoilerOverlay> createState() => _SpoilerOverlayState();
}

class _SpoilerOverlayState extends State<SpoilerOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late bool _revealed;

  @override
  void initState() {
    super.initState();
    _revealed = !widget.isSpoiler || widget.initiallyRevealed;
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 160),
      value: _revealed ? 1 : 0,
    );
  }

  @override
  void didUpdateWidget(covariant SpoilerOverlay oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReveal = !widget.isSpoiler || widget.initiallyRevealed;
    if (oldWidget.isSpoiler != widget.isSpoiler ||
        oldWidget.initiallyRevealed != widget.initiallyRevealed) {
      _revealed = shouldReveal;
      unawaited(_revealed ? _controller.forward() : _controller.reverse());
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _reveal() {
    if (_revealed) {
      return;
    }
    setState(() => _revealed = true);
    unawaited(_controller.forward());
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isSpoiler) {
      return widget.child;
    }

    return GestureDetector(
      onTap: _reveal,
      child: Stack(
        fit: StackFit.passthrough,
        children: [
          widget.child,
          Positioned.fill(
            child: IgnorePointer(
              ignoring: _revealed,
              child: FadeTransition(
                opacity: ReverseAnimation(_controller),
                child: ColoredBox(
                  color: context.colors.spoilerBackground,
                  child: Center(
                    child: Text(
                      'Spoiler',
                      style: context.textStyles.bodySmall.copyWith(
                        color: context.colors.textPrimary,
                        fontWeight: FontWeight.w600,
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
}
