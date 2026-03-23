import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/ui/tappable/fluxer_tappable.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// Builder for action menu items that receives a close callback.
typedef FluxerActionMenuBuilder =
    List<Widget> Function(BuildContext context, VoidCallback close);

/// Context menu shown at a specific screen position.
///
/// Use [FluxerActionMenu.show] to display the menu as an overlay.
class FluxerActionMenu {
  FluxerActionMenu._();

  /// Shows an action menu at [position] with items from [builder].
  ///
  /// The menu is dismissed when tapping outside, pressing Escape,
  /// or calling the `close` callback passed to [builder].
  static Future<void> show(
    BuildContext context, {
    required Offset position,
    required FluxerActionMenuBuilder builder,
  }) {
    final completer = Completer<void>();
    final overlay = Overlay.of(context);
    late final OverlayEntry entry;
    late final AnimationController animationController;

    animationController = AnimationController(
      vsync: overlay,
      duration: const Duration(milliseconds: 150),
    );

    final fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    void close() {
      unawaited(
        animationController.reverse().then((_) {
          entry.remove();
          animationController.dispose();
          if (!completer.isCompleted) {
            completer.complete();
          }
        }),
      );
    }

    entry = OverlayEntry(
      builder: (overlayContext) => _ActionMenuOverlay(
        position: position,
        fadeAnimation: fadeAnimation,
        onDismiss: close,
        builder: builder,
      ),
    );

    overlay.insert(entry);
    unawaited(animationController.forward());

    return completer.future;
  }
}

class _ActionMenuOverlay extends StatelessWidget {
  const _ActionMenuOverlay({
    required this.position,
    required this.fadeAnimation,
    required this.onDismiss,
    required this.builder,
  });

  final Offset position;
  final Animation<double> fadeAnimation;
  final VoidCallback onDismiss;
  final FluxerActionMenuBuilder builder;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return KeyboardListener(
      focusNode: FocusNode()..requestFocus(),
      autofocus: true,
      onKeyEvent: (event) {
        if (event is KeyDownEvent &&
            event.logicalKey == LogicalKeyboardKey.escape) {
          onDismiss();
        }
      },
      child: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onTap: onDismiss,
              behavior: HitTestBehavior.opaque,
              child: const ColoredBox(color: Colors.transparent),
            ),
          ),
          Positioned(
            left: position.dx,
            top: position.dy,
            child: FadeTransition(
              opacity: fadeAnimation,
              child: IntrinsicWidth(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: colors.backgroundFloating,
                    borderRadius: layout.radiusSm,
                    border: Border.all(color: colors.backgroundModifierAccent),
                    boxShadow: const [
                      BoxShadow(
                        color: Color.fromRGBO(0, 0, 0, 0.2),
                        blurRadius: 8,
                        offset: Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: layout.s1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: builder(context, onDismiss),
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

/// A single item in a [FluxerActionMenu].
///
/// Uses [FluxerTappable] for consistent hover behaviour.
class FluxerMenuItem extends StatelessWidget {
  const FluxerMenuItem({
    required this.label,
    required this.onPressed,
    this.icon,
    this.isDanger = false,
    super.key,
  });

  final String label;
  final VoidCallback onPressed;
  final PhosphorIconData? icon;
  final bool isDanger;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final textStyles = context.textStyles;
    final layout = context.layout;

    final foreground = isDanger ? colors.statusDanger : colors.textPrimary;

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: layout.s1),
      child: FluxerTappable(
        onTap: onPressed,
        builder: (context, states) {
          final isHovered = states.contains(WidgetState.hovered);

          return AnimatedContainer(
            duration: context.motion.fast,
            curve: context.motion.curve,
            decoration: BoxDecoration(
              color: isHovered
                  ? colors.backgroundModifierHover
                  : Colors.transparent,
              borderRadius: layout.radiusSm,
            ),
            padding: EdgeInsets.symmetric(
              horizontal: layout.s3,
              vertical: layout.s2,
            ),
            child: Row(
              children: [
                if (icon != null) ...[
                  PhosphorIcon(icon!, size: 20, color: foreground),
                  SizedBox(width: layout.s3),
                ],
                Expanded(
                  child: Text(
                    label,
                    style: textStyles.bodyMedium.copyWith(color: foreground),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// A thin horizontal divider for use inside [FluxerActionMenu].
class FluxerMenuDivider extends StatelessWidget {
  const FluxerMenuDivider({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final layout = context.layout;

    return Padding(
      padding: EdgeInsets.symmetric(vertical: layout.s1),
      child: ColoredBox(
        color: colors.backgroundModifierAccent,
        child: const SizedBox(height: 1, width: double.infinity),
      ),
    );
  }
}
