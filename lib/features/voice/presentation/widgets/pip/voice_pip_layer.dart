import 'dart:async';

import 'package:flutter/physics.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/tappable/fluxer_gesture_detector.dart';
import 'package:fluxer_app/features/ui/voice/fluxer_live_badge.dart';
import 'package:fluxer_app/features/ui/voice/voice_participant_media_tile.dart';
import 'package:fluxer_app/features/voice/presentation/widgets/pip/voice_pip_video.dart';
import 'package:fluxer_app/features/voice/providers/pending_incoming_voice_calls_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_active_speakers_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_call_overlay_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_pip_providers.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';
import 'package:fluxer_app/features/voice/utils/voice_participant_tile_id.dart';
import 'package:fluxer_app/features/voice/utils/voice_phone_call_layout.dart';
import 'package:fluxer_app/features/voice/utils/voice_pip_morph.dart';
import 'package:fluxer_app/features/voice/utils/voice_pip_snap.dart';
import 'package:fluxer_app/features/voice/utils/voice_pip_subscribe.dart';
import 'package:fluxer_app/features/voice/utils/voice_pip_visibility.dart';
import 'package:fluxer_app/features/voice/utils/voice_session_navigation.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_app/shared/utils/fluxer_haptics.dart';

const Key kVoiceInAppPipKey = Key('voice-in-app-pip');

class VoicePipLayer extends ConsumerStatefulWidget {
  const VoicePipLayer({required this.child, super.key});

  final Widget child;

  @override
  ConsumerState<VoicePipLayer> createState() => _VoicePipLayerState();
}

class _VoicePipLayerState extends ConsumerState<VoicePipLayer>
    with TickerProviderStateMixin {
  static const SpringDescription _kSnapSpring = SpringDescription(
    mass: 0.9,
    stiffness: 150,
    damping: 18,
  );

  late final AnimationController _moveController;
  late final AnimationController _morphController;
  late final AnimationController _settleController;
  late final CurvedAnimation _morphT;
  late final Listenable _flightTick;
  Tween<Offset>? _moveTween;
  Offset? _visualOrigin;
  var _dragging = false;
  Offset? _dragOrigin;
  var _playedMoveHaptic = false;
  var _showedPip = false;
  var _wasOnCall = false;
  Rect? _lastSlotRect;
  VoicePipHeroFlight? _flight;
  VoicePipOverlayPhase _phase = VoicePipOverlayPhase.hidden;
  Rect? _frozenPipRect;
  var _expandWaitFrames = 0;
  var _holdCollapseAtFullscreen = false;
  final GlobalKey _featuredVideoKey = GlobalKey(
    debugLabel: 'voice-pip-featured-video',
  );

  @override
  void initState() {
    super.initState();
    _moveController = AnimationController.unbounded(vsync: this)
      ..addListener(_onMoveTick)
      ..addStatusListener((AnimationStatus status) {
        if (status != AnimationStatus.completed) {
          return;
        }
        final Offset? end = _moveTween?.end;
        if (end == null) {
          return;
        }
        setState(() {
          _visualOrigin = end;
        });
      });
    _morphController =
        AnimationController(
          vsync: this,
          duration: kVoiceCallPhoneTransitionDuration,
        )..addStatusListener((AnimationStatus status) {
          if (status == AnimationStatus.completed &&
              _phase == VoicePipOverlayPhase.expanding) {
            _morphController.duration = kVoiceCallPhoneTransitionDuration;
            _onMorphArrivedExpanded();
          } else if (status == AnimationStatus.dismissed &&
              _phase == VoicePipOverlayPhase.collapsing) {
            _morphController.duration = kVoiceCallPhoneTransitionDuration;
            _onMorphArrivedCollapsed();
          }
        });
    _morphT = CurvedAnimation(
      parent: _morphController,
      curve: Curves.fastOutSlowIn,
      reverseCurve: Curves.fastOutSlowIn.flipped,
    );
    _settleController = AnimationController(
      vsync: this,
      duration: kVoicePipSettleDuration,
    );
    _flightTick = Listenable.merge(<Listenable>[
      _morphController,
      _settleController,
    ]);
  }

  @override
  void dispose() {
    _moveController.dispose();
    _morphT.dispose();
    _settleController.dispose();
    _morphController.dispose();
    super.dispose();
  }

  void _onMoveTick() {
    final Tween<Offset>? tween = _moveTween;
    if (tween == null) {
      return;
    }
    setState(() {
      _visualOrigin = tween.transform(_moveController.value);
    });
  }

  void _stopMove() {
    _moveController.stop();
    _moveTween = null;
  }

  void _setPhase(VoicePipOverlayPhase phase) {
    _phase = phase;
    ref.read(voicePipOverlayPhaseProvider.notifier).setPhase(phase);
  }

  Rect? _slotRect() => voicePipSlotRectOf(context);

  EdgeInsets _safeInsets(BuildContext context) {
    final MediaQueryData mq = MediaQuery.of(context);
    final layout = context.layout;
    double bottom = mq.padding.bottom + mq.viewInsets.bottom;
    double left = mq.padding.left;
    final double top = mq.padding.top;
    final double right = mq.padding.right;
    if (isMobileLayout(context)) {
      bottom += layout.mobileBottomNavHeight + 1;
    } else {
      left += layout.guildListWidth + layout.sidebarWidth;
      bottom += layout.userAreaHeight;
    }
    return EdgeInsets.fromLTRB(left, top, right, bottom);
  }

  void _animateOriginTo(Offset target, {Offset velocity = Offset.zero}) {
    final Offset start = _visualOrigin ?? target;
    final Offset delta = target - start;
    final double distance = delta.distance;
    if (distance < 0.5) {
      setState(() {
        _visualOrigin = target;
      });
      return;
    }
    _moveTween = Tween<Offset>(begin: start, end: target);
    final double along =
        (velocity.dx * delta.dx + velocity.dy * delta.dy) / distance;
    final double unitVelocity = (along / distance).clamp(-3.2, 3.2);
    _moveController.animateWith(
      SpringSimulation(_kSnapSpring, 0, 1, unitVelocity),
    );
  }

  Rect _expandTarget({Size? pipSize}) {
    return _slotRect() ??
        _lastSlotRect ??
        voicePipFallbackExpandRect(
          viewport: MediaQuery.sizeOf(context),
          padding: MediaQuery.paddingOf(context),
          pipSize: pipSize,
        );
  }

  void _maybeFollowExpandSlot() {
    if (_phase != VoicePipOverlayPhase.expanding &&
        _phase != VoicePipOverlayPhase.settling) {
      return;
    }
    final Rect? slot = _slotRect();
    if (slot == null) {
      return;
    }
    _lastSlotRect = slot;
    _flight?.end = slot;
  }

  void _scheduleExpandFlight() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _phase != VoicePipOverlayPhase.expanding) {
        return;
      }
      _tryStartExpandFlight();
    });
  }

  void _tryStartExpandFlight() {
    final Rect pip =
        _frozenPipRect ??
        _currentPipRect(
          featuredTileId: ref.read(voicePipFeaturedTileIdProvider),
        );
    final Rect? slot = _slotRect();
    if (slot != null) {
      _lastSlotRect = slot;
      _flight = VoicePipHeroFlight(begin: pip, end: slot);
      _startExpandAnimation();
      setState(() {});
      return;
    }
    _expandWaitFrames++;
    if (_expandWaitFrames >= 4 && _lastSlotRect != null) {
      _flight = VoicePipHeroFlight(begin: pip, end: _lastSlotRect!);
      _startExpandAnimation();
      setState(() {});
      return;
    }
    if (_expandWaitFrames >= 8) {
      _flight = VoicePipHeroFlight(
        begin: pip,
        end: _expandTarget(pipSize: pip.size),
      );
      _startExpandAnimation();
      setState(() {});
      return;
    }
    _scheduleExpandFlight();
  }

  void _startExpandAnimation() {
    if (_morphController.isAnimating || _morphController.value > 0) {
      return;
    }
    _morphController.duration = kVoiceCallPhoneTransitionDuration;
    _morphController.forward(from: 0);
  }

  void _resetSettle() {
    _settleController
      ..stop()
      ..value = 0;
  }

  void _armCollapse({required Rect pipRect}) {
    if (_phase == VoicePipOverlayPhase.collapsing ||
        _phase == VoicePipOverlayPhase.pip) {
      return;
    }
    _stopMove();
    _frozenPipRect = pipRect;
    final Rect fromSlot =
        _lastSlotRect ?? _slotRect() ?? _expandTarget(pipSize: pipRect.size);
    _flight = VoicePipHeroFlight(begin: pipRect, end: fromSlot);
    _phase = VoicePipOverlayPhase.collapsing;
    _holdCollapseAtFullscreen = true;
  }

  void _startArmedCollapse() {
    if (!mounted || _phase != VoicePipOverlayPhase.collapsing) {
      return;
    }
    _resetSettle();
    final double from = _morphController.value == 0
        ? 1
        : _morphController.value;
    _morphController
      ..stop()
      ..duration = kVoiceCallPhoneTransitionDuration
      ..value = from;
    _holdCollapseAtFullscreen = false;
    _setPhase(VoicePipOverlayPhase.collapsing);
    _morphController.reverse(from: from);
  }

  void _beginExpand({required Rect pipRect}) {
    if (_phase == VoicePipOverlayPhase.expanding) {
      return;
    }
    _holdCollapseAtFullscreen = false;
    armVoicePipSkipPhoneEnter();
    _resetSettle();
    _stopMove();
    _frozenPipRect = pipRect;
    _expandWaitFrames = 0;
    _flight = VoicePipHeroFlight(begin: pipRect, end: pipRect);
    _setPhase(VoicePipOverlayPhase.expanding);
    _morphController
      ..stop()
      ..value = 0;
    setState(() {});
    _scheduleExpandFlight();
  }

  void _onMorphArrivedExpanded() {
    if (!mounted || _phase != VoicePipOverlayPhase.expanding) {
      return;
    }
    takeVoicePipSkipPhoneEnter();
    _lastSlotRect = _slotRect() ?? _flight?.end ?? _lastSlotRect;
    _frozenPipRect = null;
    _setPhase(VoicePipOverlayPhase.settling);
    setState(() {});
    unawaited(
      _settleController.forward(from: 0).whenComplete(_onSettleFinished),
    );
  }

  void _onSettleFinished() {
    if (!mounted || _phase != VoicePipOverlayPhase.settling) {
      return;
    }
    _lastSlotRect = _slotRect() ?? _flight?.end ?? _lastSlotRect;
    _flight = null;
    _setPhase(VoicePipOverlayPhase.hidden);
    setState(() {});
  }

  void _onMorphArrivedCollapsed() {
    if (!mounted) {
      return;
    }
    takeVoicePipSkipPhoneEnter();
    final Rect? landed = _flight?.rectAt(0) ?? _frozenPipRect;
    if (landed != null) {
      _visualOrigin = landed.topLeft;
    }
    _flight = null;
    _frozenPipRect = null;
    _holdCollapseAtFullscreen = false;
    _setPhase(VoicePipOverlayPhase.pip);
    setState(() {});
  }

  void _hideOverlay() {
    _morphController.stop();
    _resetSettle();
    takeVoicePipSkipPhoneEnter();
    _flight = null;
    _frozenPipRect = null;
    _holdCollapseAtFullscreen = false;
    _setPhase(VoicePipOverlayPhase.hidden);
    setState(() {});
  }

  Widget _flightVideo({
    required String tileId,
    required bool speaking,
    required bool isScreen,
    required double t,
    bool dragging = false,
    bool ignorePointers = true,
  }) {
    final double decoration = voicePipDecorationOpacity(t);
    final double radius = voicePipMorphRadius(t);
    final double lift = dragging ? 1 : decoration;
    final Widget scaled = AnimatedScale(
      key: _featuredVideoKey,
      scale: dragging ? 1.04 : 1,
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(radius),
          boxShadow: lift <= 0.01
              ? const <BoxShadow>[]
              : <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withValues(
                      alpha: (dragging ? 0.45 : 0.28) * lift,
                    ),
                    blurRadius: (dragging ? 22 : 16) * lift,
                    offset: Offset(0, (dragging ? 10 : 8) * lift),
                  ),
                ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(radius),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              VoicePipVideo(tileId: tileId),
              if (decoration > 0.01 && speaking && t < 0.35)
                DecoratedBox(
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: context.colors.statusOnline.withValues(
                        alpha: decoration,
                      ),
                      width: 2.5 * decoration,
                    ),
                    borderRadius: BorderRadius.circular(radius),
                  ),
                ),
              if (decoration > 0.01 && isScreen)
                Positioned(
                  left: 8,
                  bottom: 8,
                  child: Opacity(
                    opacity: decoration,
                    child: const FluxerLiveBadge(),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (ignorePointers) {
      return IgnorePointer(child: scaled);
    }
    return scaled;
  }

  Widget _buildPip({
    required BuildContext context,
    required String tileId,
    required VoiceSessionState voice,
  }) {
    final parsed = parseVoiceParticipantTileId(tileId);
    final bool isScreen =
        parsed?.source == VoiceParticipantTileSource.screenShare;
    final Size viewport = MediaQuery.sizeOf(context);
    final Size card = voicePipCardSize(
      viewport: viewport,
      isScreenShare: isScreen,
      hasVideo: ref.watch(voicePipFeaturedHasVideoProvider),
    );
    final Rect safe = voicePipSafeRect(
      viewport: viewport,
      insets: _safeInsets(context),
    );
    final Offset stored =
        ref.watch(voicePipPlacementProvider) ??
        voicePipDefaultOrigin(safeRect: safe, cardSize: card);
    final Offset origin = voicePipClampOrigin(
      origin: _dragging ? (_dragOrigin ?? stored) : (_visualOrigin ?? stored),
      cardSize: card,
      safeRect: safe,
    );
    final Rect pipRect = origin & card;
    final bool speaking =
        !isScreen &&
        parsed != null &&
        ref.watch(
          voiceActiveSpeakersProvider.select(
            (VoiceActiveSpeakersState s) =>
                s.speakingKeys.contains(parsed.identity),
          ),
        );
    if (voicePipIsInFlight(_phase)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _maybeFollowExpandSlot();
        }
      });
      final VoicePipHeroFlight flight =
          _flight ??
          VoicePipHeroFlight(
            begin: pipRect,
            end: _expandTarget(pipSize: pipRect.size),
          );
      final double t = _phase == VoicePipOverlayPhase.settling
          ? 1
          : (_holdCollapseAtFullscreen ? 1 : _morphT.value);
      final Rect? slot = _slotRect() ?? _lastSlotRect;
      final Rect liveRect = switch (_phase) {
        VoicePipOverlayPhase.settling => slot ?? flight.end,
        VoicePipOverlayPhase.collapsing => voicePipFlightRect(
          flight: flight,
          t: t,
          snapToSlot: false,
        ),
        _ => voicePipFlightRect(flight: flight, t: t, slot: slot),
      };
      final double fade = _phase == VoicePipOverlayPhase.settling
          ? 1 - _settleController.value
          : 1;
      return Positioned.fromRect(
        rect: liveRect,
        child: Opacity(
          opacity: fade,
          child: KeyedSubtree(
            key: kVoicePipFlightKey,
            child: _flightVideo(
              tileId: tileId,
              speaking: speaking,
              isScreen: isScreen,
              t: t,
            ),
          ),
        ),
      );
    }
    return Positioned.fromRect(
      rect: pipRect,
      child: FluxerGestureDetector(
        key: kVoiceInAppPipKey,
        behavior: HitTestBehavior.opaque,
        onTap: () {
          _beginExpand(pipRect: pipRect);
          navigateToActiveVoiceSession(context, voice: voice);
        },
        onPanStart: (_) {
          _stopMove();
          _playedMoveHaptic = false;
          setState(() {
            _dragging = true;
            _dragOrigin = _visualOrigin ?? origin;
            _visualOrigin = _dragOrigin;
          });
        },
        onPanUpdate: (DragUpdateDetails details) {
          if (voicePipShouldPlayMoveHaptic(
            alreadyPlayed: _playedMoveHaptic,
            delta: details.delta,
          )) {
            _playedMoveHaptic = true;
            FluxerHaptics.medium();
          }
          setState(() {
            _dragOrigin = voicePipClampOrigin(
              origin: (_dragOrigin ?? origin) + details.delta,
              cardSize: card,
              safeRect: safe,
            );
            _visualOrigin = _dragOrigin;
          });
        },
        onPanEnd: (DragEndDetails details) {
          _playedMoveHaptic = false;
          final Offset from = _dragOrigin ?? origin;
          final Offset release = voicePipOriginAfterRelease(
            origin: from,
            cardSize: card,
            safeRect: safe,
            velocity: details.velocity.pixelsPerSecond,
          );
          ref.read(voicePipPlacementProvider.notifier).setOffset(release);
          setState(() {
            _dragging = false;
            _dragOrigin = null;
            _visualOrigin = from;
          });
          _animateOriginTo(release, velocity: details.velocity.pixelsPerSecond);
        },
        onPanCancel: () {
          _playedMoveHaptic = false;
          final Offset from = _dragOrigin ?? _visualOrigin ?? origin;
          final Offset release = voicePipSnapToNearestEdge(
            origin: from,
            cardSize: card,
            safeRect: safe,
          );
          ref.read(voicePipPlacementProvider.notifier).setOffset(release);
          setState(() {
            _dragging = false;
            _dragOrigin = null;
            _visualOrigin = from;
          });
          _animateOriginTo(release);
        },
        child: _flightVideo(
          tileId: tileId,
          speaking: speaking,
          isScreen: isScreen,
          t: 0,
          dragging: _dragging,
          ignorePointers: false,
        ),
      ),
    );
  }

  Rect _currentPipRect({required String? featuredTileId}) {
    final Size viewport = MediaQuery.sizeOf(context);
    final parsed = featuredTileId == null
        ? null
        : parseVoiceParticipantTileId(featuredTileId);
    final Size card = voicePipCardSize(
      viewport: viewport,
      isScreenShare: parsed?.source == VoiceParticipantTileSource.screenShare,
      hasVideo: ref.read(voicePipFeaturedHasVideoProvider),
    );
    final Rect safe = voicePipSafeRect(
      viewport: viewport,
      insets: _safeInsets(context),
    );
    final Offset stored =
        ref.read(voicePipPlacementProvider) ??
        voicePipDefaultOrigin(safeRect: safe, cardSize: card);
    final Offset origin = voicePipClampOrigin(
      origin: _visualOrigin ?? stored,
      cardSize: card,
      safeRect: safe,
    );
    return origin & card;
  }

  @override
  Widget build(BuildContext context) {
    final VoiceSessionState voice = ref.watch(voiceSessionProvider);
    final String? featuredTileId = ref.watch(voicePipFeaturedTileIdProvider);
    final bool onCall = ref.watch(voicePipOnSessionCallRouteProvider);
    final String? routeChannelId = ref.watch(
      routeStateProvider.select((RouteState s) => s.channelId),
    );
    final bool embedded =
        isWideLayout(context) &&
        routeChannelId != null &&
        showsEmbeddedDmVoicePanel(channelId: routeChannelId, voice: voice) &&
        !onCall;
    final bool incomingBlocking = ref
        .watch(pendingIncomingVoiceChannelIdsProvider)
        .isNotEmpty;
    final bool collapsed = voicePipShouldShowCollapsed(
      voice: voice,
      onSessionCallRoute: onCall,
      showsEmbeddedDmPanel: embedded,
      hasFeaturedVisual: featuredTileId != null,
      incomingCallBlocking: incomingBlocking,
    );
    final bool exiting = ref.watch(
      voiceCallOverlayProvider.select((VoiceCallOverlayState s) => s.isExiting),
    );

    final bool leavingCallUi =
        !onCall &&
        _wasOnCall &&
        !exiting &&
        voice.isInVoice &&
        featuredTileId != null;

    if (collapsed && _phase == VoicePipOverlayPhase.hidden && !leavingCallUi) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted || !collapsed) {
          return;
        }
        if (_phase != VoicePipOverlayPhase.hidden) {
          return;
        }
        _setPhase(VoicePipOverlayPhase.pip);
        setState(() {});
      });
    }

    if (onCall && _showedPip && _phase == VoicePipOverlayPhase.pip) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _beginExpand(
            pipRect: _currentPipRect(featuredTileId: featuredTileId),
          );
        }
      });
    }

    if (leavingCallUi &&
        (_phase == VoicePipOverlayPhase.hidden ||
            _phase == VoicePipOverlayPhase.expanding ||
            _phase == VoicePipOverlayPhase.settling)) {
      _armCollapse(pipRect: _currentPipRect(featuredTileId: featuredTileId));
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _startArmedCollapse();
        }
      });
    }

    final bool morphing = voicePipIsInFlight(_phase);

    if ((!voice.isInVoice || featuredTileId == null) &&
        _phase != VoicePipOverlayPhase.hidden) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _hideOverlay();
        }
      });
    }

    _wasOnCall = onCall;
    _showedPip = collapsed && featuredTileId != null;

    if (collapsed && voice.liveKitRoom != null) {
      unawaited(
        syncCollapsedVoiceVideoSubscriptions(
          room: voice.liveKitRoom!,
          featuredTileId: featuredTileId,
        ),
      );
    }

    final bool showOverlay =
        featuredTileId != null &&
        voice.isInVoice &&
        (collapsed || morphing || _phase == VoicePipOverlayPhase.pip);

    return AnimatedBuilder(
      animation: _flightTick,
      builder: (BuildContext context, Widget? _) {
        return Stack(
          children: <Widget>[
            widget.child,
            if (showOverlay)
              _buildPip(context: context, tileId: featuredTileId, voice: voice),
          ],
        );
      },
    );
  }
}
