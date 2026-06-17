import 'dart:async';
import 'dart:math' as math;

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

/// How long the swipe must be held (roughly still) past the reply threshold
/// before the armed action escalates from reply to edit.
const Duration _kEditHoldDelay = Duration(milliseconds: 400);

/// Per-update drag delta above which the dwell timer restarts, so edit arms
/// only once the swipe settles rather than during a continuous drag.
const double _kHoldMovementSlop = 3;

/// Diameter of the hold-progress ring drawn around the action pill.
const double _kHoldRingSize = 48;
const double _kHoldRingStroke = 3;

/// Wraps [child] with a swipe-left gesture that shortcuts to reply, with an
/// optional hold-to-edit escalation.
///
/// The child follows the finger leftward, capped at [_kMaxDragFraction] of the
/// screen width, while an action icon fades and scales in from the right.
/// Releasing past the trigger threshold invokes [onReply] with a haptic
/// impulse. When [onEdit] is non-null (the message is editable by the current
/// user), holding the swipe roughly still past the threshold for
/// [_kEditHoldDelay] escalates the armed action to edit: a progress ring fills
/// around the pill, the icon morphs from a reply arrow to a pencil, a heavier
/// haptic fires, and releasing then invokes [onEdit] instead of [onReply].
/// Either way the child springs back to its original position.
class SwipeToReply extends StatefulWidget {
  const SwipeToReply({
    required this.child,
    required this.onReply,
    this.onEdit,
    this.enabled = true,
    super.key,
  });

  final Widget child;
  final VoidCallback onReply;

  /// Invoked when the swipe is held past the threshold long enough to escalate
  /// to edit. Null when the message is not editable by the current user, which
  /// also disables the hold-to-edit affordance entirely.
  final VoidCallback? onEdit;
  final bool enabled;

  @override
  State<SwipeToReply> createState() => _SwipeToReplyState();
}

class _SwipeToReplyState extends State<SwipeToReply>
    with TickerProviderStateMixin {
  late final AnimationController _springController;
  late final AnimationController _holdController;
  Animation<double>? _springAnimation;
  double _dragOffset = 0;
  double _maxDrag = 0;
  double _triggerOffset = 0;
  bool _hasCrossedThreshold = false;
  bool _armedEdit = false;

  bool get _canEdit => widget.onEdit != null;

  @override
  void initState() {
    super.initState();
    _springController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: _kSpringBackMs),
    );
    _holdController = AnimationController(
      vsync: this,
      duration: _kEditHoldDelay,
    )..addStatusListener(_onHoldStatus);
  }

  @override
  void dispose() {
    _springController.dispose();
    _holdController.dispose();
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
    _armedEdit = false;
    _holdController
      ..stop()
      ..value = 0;
    _springAnimation?.removeListener(_onSpringTick);
    _springAnimation = null;
    _springController.stop();
  }

  void _handleDragUpdate(DragUpdateDetails details) {
    final next = (_dragOffset + details.delta.dx).clamp(-_maxDrag, 0.0);
    final bool pastThreshold = next <= -_triggerOffset;
    if (!_hasCrossedThreshold && pastThreshold) {
      _hasCrossedThreshold = true;
      unawaited(HapticFeedback.mediumImpact());
      if (_canEdit) {
        unawaited(_holdController.forward(from: 0));
      }
    } else if (_hasCrossedThreshold && !pastThreshold) {
      _hasCrossedThreshold = false;
      _cancelHold();
    } else if (_hasCrossedThreshold &&
        _canEdit &&
        !_armedEdit &&
        details.delta.dx.abs() > _kHoldMovementSlop) {
      // Still dragging past the threshold -- restart the dwell timer so edit
      // arms only once the swipe is held roughly still.
      unawaited(_holdController.forward(from: 0));
    }
    setState(() {
      _dragOffset = next;
    });
  }

  void _handleDragEnd(DragEndDetails details) {
    final bool shouldEdit = _armedEdit && _canEdit;
    _holdController.stop();
    if (shouldEdit) {
      widget.onEdit!.call();
    } else if (_dragOffset <= -_triggerOffset) {
      widget.onReply();
    }
    _armedEdit = false;
    _holdController.value = 0;
    _animateBack();
  }

  void _handleDragCancel() {
    _cancelHold();
    _animateBack();
  }

  void _cancelHold() {
    _armedEdit = false;
    _holdController
      ..stop()
      ..value = 0;
  }

  void _onHoldStatus(AnimationStatus status) {
    if (status == AnimationStatus.completed &&
        _hasCrossedThreshold &&
        _canEdit &&
        !_armedEdit) {
      unawaited(HapticFeedback.heavyImpact());
      setState(() {
        _armedEdit = true;
      });
    }
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
    final double leadingReserve = leadingEdgeHorizontalSwipeReserveWidth(
      context,
    );
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
        if (progress > 0) _buildActionIcon(context, progress),
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

  Widget _buildActionIcon(BuildContext context, double progress) {
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
              child: AnimatedBuilder(
                animation: _holdController,
                builder: (context, _) {
                  final double holdProgress = _armedEdit
                      ? 1.0
                      : _holdController.value;
                  final bool showRing = _canEdit && holdProgress > 0;
                  final Color ringColor = context.colors.brandPrimaryLight;
                  return SizedBox(
                    width: _kHoldRingSize,
                    height: _kHoldRingSize,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        if (showRing)
                          CustomPaint(
                            size: const Size.square(_kHoldRingSize),
                            painter: _HoldRingPainter(
                              progress: holdProgress,
                              color: ringColor,
                              trackColor: ringColor.withValues(alpha: 0.2),
                            ),
                          ),
                        Container(
                          width: _kIconPillSize,
                          height: _kIconPillSize,
                          decoration: BoxDecoration(
                            color: context.colors.brandPrimary,
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: PhosphorIcon(
                            _armedEdit
                                ? PhosphorIconsFill.pencilSimple
                                : PhosphorIconsFill.arrowBendUpLeft,
                            size: _kIconSize,
                            color: context.colors.textOnBrandPrimary,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Paints the circular hold-progress affordance around the action pill: a
/// faint full-circle track with a brand-colored arc that sweeps clockwise
/// from the top as [progress] runs 0 -> 1.
class _HoldRingPainter extends CustomPainter {
  const _HoldRingPainter({
    required this.progress,
    required this.color,
    required this.trackColor,
  });

  final double progress;
  final Color color;
  final Color trackColor;

  @override
  void paint(Canvas canvas, Size size) {
    final Offset center = size.center(Offset.zero);
    final double radius = (size.shortestSide - _kHoldRingStroke) / 2;
    final Paint track = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kHoldRingStroke
      ..color = trackColor;
    canvas.drawCircle(center, radius, track);
    final double sweep = progress.clamp(0.0, 1.0) * 2 * math.pi;
    if (sweep <= 0) {
      return;
    }
    final Paint arc = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = _kHoldRingStroke
      ..strokeCap = StrokeCap.round
      ..color = color;
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -math.pi / 2,
      sweep,
      false,
      arc,
    );
  }

  @override
  bool shouldRepaint(_HoldRingPainter oldDelegate) =>
      oldDelegate.progress != progress ||
      oldDelegate.color != color ||
      oldDelegate.trackColor != trackColor;
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
