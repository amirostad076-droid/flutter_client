import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/shell/presentation/swipe_constants.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const double _kMaxDragFraction = 0.30;
const double _kTriggerFraction = 0.20;
const int _kSpringBackMs = 180;
const double _kIconPillSize = 36;
const double _kIconSize = 20;
const double _kIconMinScale = 0.6;
const double _kIconRightPadding = 20;
const double _kMaxCornerRadius = 8;

/// Wraps [child] with a swipe-left-to-reply gesture.
///
/// The child follows the finger leftward, capped at
/// [_kMaxDragFraction] of the screen width, while a
/// reply icon fades and scales in from the right. If the
/// user releases past the trigger threshold, [onReply] is
/// invoked with a haptic impulse. Either way, the child
/// springs back to its original position.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    required this.child,
    required this.onReply,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback onReply;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with SingleTickerProviderStateMixin {
  late final AnimationController _springController;
  Animation<double>? _springAnimation;
  double _dragOffset = 0;
  double _maxDrag = 0;
  double _triggerOffset = 0;
  bool _hasCrossedThreshold = false;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSpringBackMs),
    );
  }

  @override
  void dispose() {
    _springController.dispose();
    super.dispose();
  }

  void _measureBounds() {
    final width = MediaQuery.sizeOf(context).width;
    _maxDrag = width * _kMaxDragFraction;
    _triggerOffset = width * _kTriggerFraction;
  }

  void _handleDragStart(DragStartDetails details) {
    _measureBounds();
    _hasCrossedThreshold = false;
    _springAnimation?.removeListener(_onSpringTick);
    _springAnimation = null;
    _springController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = (_dragOffset + details.delta.dx).clamp(-_maxDrag, 0.0);
    if (!_hasCrossedThreshold && next <= -_triggerOffset) {
      _hasCrossedThreshold = true;
      unawaited(HapticFeedback.mediumImpact());
    } else if (_hasCrossedThreshold && next > -_triggerOffset) {
      _hasCrossedThreshold = false;
    }
    setState(() {
      _dragOffset = next;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    if (_dragOffset <= -_triggerOffset) {
      widget.onReply();
    }
    _animateBack();
  }

  void _handleDragCancel() {
    _animateBack();
  }

  void _animateBack() {
    if (_dragOffset == 0) {
      return;
    }
    final start = _dragOffset;
    _springController
      ..stop()
      ..reset();
    final animation = Tween<double>(begin: start, end: 0).animate(
      CurvedAnimation(parent: _springController, curve: Curves.easeOut),
    )..addListener(_onSpringTick);
    _springAnimation = animation;
    unawaited(_springController.forward());
  }

  void _onSpringTick() {
    if (!mounted) {
      return;
    }
    setState(() {
      _dragOffset = _springAnimation?.value ?? 0;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      return widget.child;
    }
    if (_maxDrag == 0) {
      _measureBounds();
    }
    final progress = _maxDrag == 0
        ? 0.0
        : (-_dragOffset / _maxDrag).clamp(0.0, 1.0);
    final cornerRadius = _kMaxCornerRadius * progress;
    final double leadingReserve =
        leadingEdgeHorizontalSwipeReserveWidth(context);
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Transform.translate(
          offset: Offset(_dragOffset, 0),
          child: ClipRRect(
            borderRadius: BorderRadius.only(
              topRight: Radius.circular(cornerRadius),
              bottomRight: Radius.circular(cornerRadius),
            ),
            child: widget.child,
          ),
        ),
        if (progress > 0) _buildReplyIcon(context, progress),
        PositionedDirectional(
          start: leadingReserve,
          top: 0,
          end: 0,
          bottom: 0,
          child: RawGestureDetector(
            behavior: HitTestBehavior.translucent,
            gestures: <Type, GestureRecognizerFactory>{
              _LeftwardHorizontalDragRecognizer:
                  GestureRecognizerFactoryWithHandlers<
                    _LeftwardHorizontalDragRecognizer
                  >(_LeftwardHorizontalDragRecognizer.new, (recognizer) {
                    recognizer
                      ..onStart = _handleDragStart
                      ..onUpdate = _handleDragUpdate
                      ..onEnd = _handleDragEnd
                      ..onCancel = _handleDragCancel;
                  }),
            },
            child: const SizedBox.expand(),
          ),
        ),
      ],
    );
  }

  Widget _buildReplyIcon(BuildContext context, double progress) {
    final scale = _kIconMinScale + (1 - _kIconMinScale) * progress;
    return Positioned.fill(
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: _kIconRightPadding),
          child: Opacity(
            opacity: progress,
            child: Transform.scale(
              scale: scale,
              child: Container(
                width: _kIconPillSize,
                height: _kIconPillSize,
                decoration: BoxDecoration(
                  color: context.colors.brandPrimary,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: PhosphorIcon(
                  PhosphorIconsFill.arrowBendUpLeft,
                  size: _kIconSize,
                  color: context.colors.textOnBrandPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Horizontal drag recognizer that drops out of the gesture arena as soon
/// as the dominant drag direction is rightward, leaving the parent shell
/// drawer free to claim the gesture and open the drawer.
class _LeftwardHorizontalDragRecognizer
    extends HorizontalDragGestureRecognizer {
  _LeftwardHorizontalDragRecognizer({super.debugOwner});

  final Map<int, Offset> _initialPositions = <int, Offset>{};
  final Set<int> _resolved = <int>{};

  @override
  void addAllowedPointer(PointerDownEvent event) {
    _initialPositions[event.pointer] = event.position;
    super.addAllowedPointer(event);
  }

  @override
  void handleEvent(PointerEvent event) {
    if (event is PointerMoveEvent && !_resolved.contains(event.pointer)) {
      final start = _initialPositions[event.pointer];
      if (start != null) {
        final delta = event.position - start;
        if (delta.dx.abs() >= kTouchSlop &&
            delta.dx.abs() > delta.dy.abs() &&
            delta.dx > 0) {
          _resolved.add(event.pointer);
          resolve(GestureDisposition.rejected);
          return;
        }
      }
    }
    super.handleEvent(event);
  }

  @override
  void didStopTrackingLastPointer(int pointer) {
    _initialPositions.remove(pointer);
    _resolved.remove(pointer);
    super.didStopTrackingLastPointer(pointer);
  }

  @override
  void rejectGesture(int pointer) {
    _initialPositions.remove(pointer);
    _resolved.remove(pointer);
    super.rejectGesture(pointer);
  }
}
