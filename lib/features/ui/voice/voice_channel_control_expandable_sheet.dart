import 'dart:async' show unawaited;
import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/ui/voice/voice_channel_control_bar.dart';
import 'package:fluxer_app/features/ui/voice/voice_channel_control_panel_settings.dart';
import 'package:fluxer_app/features/voice/providers/screen_share_capability_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';

const double _kExpandedSheetHeightFraction = 0.88;
const double _kSnapVelocityThreshold = 650;
const double _kSnapMidpointFraction = 0.42;
const Key kVoiceControlSheetDragHandleKey = Key(
  'voice-control-sheet-drag-handle',
);
const Key kVoiceControlSheetDragHeaderKey = Key(
  'voice-control-sheet-drag-header',
);
const Key kVoiceControlMorphingBarKey = Key('voice-control-morphing-bar');

class VoiceCallMobilePageLayout extends ConsumerWidget {
  const VoiceCallMobilePageLayout({
    required this.channelId,
    required this.child,
    this.guildId,
    super.key,
  });

  final String? channelId;
  final String? guildId;
  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (
      bool isInVoice,
      bool isConnected,
      String? connectionId,
      String? channelId,
      String? guildId,
    ) = ref.watch(
      voiceSessionProvider.select(
        (VoiceSessionState s) => (
          s.isInVoice,
          s.isConnected,
          s.activeConnectionId,
          s.channelId,
          s.guildId,
        ),
      ),
    );
    if (!isInVoice) {
      return child;
    }
    final double footprint = voiceChannelControlCollapsedFootprint(context);
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            Padding(
              padding: EdgeInsets.only(bottom: footprint),
              child: child,
            ),
            VoiceChannelControlExpandableSheet(
              channelId: this.channelId ?? channelId,
              guildId: this.guildId ?? guildId,
              isConnected: isConnected,
              connectionId: connectionId,
              parentHeight: constraints.maxHeight,
              parentWidth: constraints.maxWidth,
            ),
          ],
        );
      },
    );
  }
}

class VoiceChannelControlExpandableSheet extends ConsumerStatefulWidget {
  const VoiceChannelControlExpandableSheet({
    required this.parentHeight,
    required this.parentWidth,
    required this.isConnected,
    this.channelId,
    this.guildId,
    this.connectionId,
    super.key,
  });

  final String? channelId;
  final String? guildId;
  final String? connectionId;
  final bool isConnected;
  final double parentHeight;
  final double parentWidth;

  @override
  ConsumerState<VoiceChannelControlExpandableSheet> createState() =>
      _VoiceChannelControlExpandableSheetState();
}

class _VoiceChannelControlExpandableSheetState
    extends ConsumerState<VoiceChannelControlExpandableSheet> {
  final ScrollController _scrollController = ScrollController();
  late double _height;
  bool _isDragging = false;
  bool _initialized = false;
  bool _panelBodyVisible = false;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  double _collapsedHeight(BuildContext context) {
    return voiceChannelControlMorphingHeaderHeight();
  }

  double _expandedHeight(BuildContext context) {
    final double bottomInset = MediaQuery.viewPaddingOf(context).bottom;
    const double outerPadding = kVoiceControlBarVerticalPadding * 2;
    final double available = widget.parentHeight - bottomInset - outerPadding;
    return (available * _kExpandedSheetHeightFraction).clamp(
      _collapsedHeight(context),
      available,
    );
  }

  double _expansionProgress(BuildContext context) {
    final double collapsed = _collapsedHeight(context);
    final double expanded = _expandedHeight(context);
    if (expanded <= collapsed) {
      return 0;
    }
    return ((_height - collapsed) / (expanded - collapsed)).clamp(0.0, 1.0);
  }

  bool _isExpanded(BuildContext context) {
    return _height > _collapsedHeight(context) + 1;
  }

  void _ensureInitialized(BuildContext context) {
    if (_initialized) {
      return;
    }
    _height = _collapsedHeight(context);
    _initialized = true;
  }

  void _adjustSheetHeight(BuildContext context, double deltaDy) {
    final double collapsed = _collapsedHeight(context);
    final double expanded = _expandedHeight(context);
    setState(() {
      _isDragging = true;
      _height = (_height - deltaDy).clamp(collapsed, expanded);
    });
  }

  void _onVerticalDragUpdate(
    BuildContext context,
    DragUpdateDetails details, {
    bool Function()? canDrag,
  }) {
    if (canDrag != null && !canDrag()) {
      return;
    }
    _adjustSheetHeight(context, details.delta.dy);
  }

  void _onVerticalDragEnd(
    BuildContext context,
    DragEndDetails details, {
    bool Function()? canDrag,
  }) {
    if (canDrag != null && !canDrag()) {
      return;
    }
    final double collapsed = _collapsedHeight(context);
    final double expanded = _expandedHeight(context);
    final double midpoint =
        collapsed + ((expanded - collapsed) * _kSnapMidpointFraction);
    final double velocity = details.primaryVelocity ?? 0;
    late final double target;
    if (velocity < -_kSnapVelocityThreshold) {
      target = expanded;
    } else if (velocity > _kSnapVelocityThreshold) {
      target = collapsed;
    } else {
      target = _height >= midpoint ? expanded : collapsed;
    }
    final double previousHeight = _height;
    setState(() {
      _isDragging = false;
      _height = target;
      if (target <= collapsed + 1) {
        _panelBodyVisible = false;
      } else {
        _panelBodyVisible = true;
      }
    });
    _playSnapHaptic(
      collapsed: collapsed,
      previousHeight: previousHeight,
      targetHeight: target,
    );
  }

  void _playSnapHaptic({
    required double collapsed,
    required double previousHeight,
    required double targetHeight,
  }) {
    final bool wasExpanded = previousHeight > collapsed + 1;
    final bool isExpanded = targetHeight > collapsed + 1;
    if (wasExpanded == isExpanded) {
      return;
    }
    if (isExpanded) {
      unawaited(HapticFeedback.mediumImpact());
      return;
    }
    unawaited(HapticFeedback.lightImpact());
  }

  void _syncPanelBodyVisibility(BuildContext context) {
    if (_isExpanded(context)) {
      _panelBodyVisible = true;
    }
  }

  bool _isPanelListAtTop() {
    return !_scrollController.hasClients || _scrollController.offset <= 0;
  }

  void _onPanelPointerMove(BuildContext context, PointerMoveEvent event) {
    if (!_panelBodyVisible || !_isPanelListAtTop()) {
      return;
    }
    if (event.delta.dy > 0) {
      _adjustSheetHeight(context, event.delta.dy);
    }
  }

  void _onPanelPointerEnd(BuildContext context, PointerEvent event) {
    if (!_isDragging) {
      return;
    }
    _onVerticalDragEnd(context, DragEndDetails());
  }

  ScrollPhysics _panelScrollPhysics() {
    if (!_panelBodyVisible) {
      return const NeverScrollableScrollPhysics();
    }
    return const AlwaysScrollableScrollPhysics(parent: ClampingScrollPhysics());
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parentHeight <= 0 || widget.parentWidth <= 0) {
      return const SizedBox.shrink();
    }
    _ensureInitialized(context);
    _syncPanelBodyVisibility(context);
    final double expansion = _expansionProgress(context);
    final double maxBarWidth = widget.parentWidth - 16;
    final bool canScreenShare = ref
        .watch(screenShareCapabilityProvider)
        .maybeWhen(data: (bool value) => value, orElse: () => false);
    final int buttonCount = voiceChannelControlButtonCount(
      canScreenShare: canScreenShare,
    );
    final double collapsedWidth = voiceChannelControlMorphingCollapsedWidth(
      buttonCount: buttonCount,
    ).clamp(0, maxBarWidth);
    final double barWidth =
        lerpDouble(collapsedWidth, maxBarWidth, expansion) ?? maxBarWidth;
    final double barRadius = voiceChannelControlMorphingBarRadius(expansion);
    final bool showScrollBody = _panelBodyVisible;
    final Duration animationDuration =
        _isDragging || MediaQuery.disableAnimationsOf(context)
        ? Duration.zero
        : context.motion.slow;
    final double collapsedBarInnerWidth =
        collapsedWidth - (kVoiceControlMorphingBarBorderWidth * 2);
    final double expandedBarInnerWidth =
        maxBarWidth - (kVoiceControlMorphingBarBorderWidth * 2);
    return Positioned(
      left: 0,
      right: 0,
      bottom: 0,
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8,
            vertical: kVoiceControlBarVerticalPadding,
          ),
          child: Align(
            alignment: Alignment.bottomCenter,
            child: AnimatedContainer(
              key: kVoiceControlMorphingBarKey,
              duration: animationDuration,
              curve: Curves.easeOutCubic,
              width: barWidth,
              height: _height,
              decoration: voiceChannelControlFloatingDecoration(
                context,
                borderRadius: BorderRadius.circular(barRadius),
              ),
              clipBehavior: Clip.antiAlias,
              child: LayoutBuilder(
                builder: (BuildContext context, BoxConstraints constraints) {
                  final double barInnerWidth =
                      constraints.maxWidth -
                      (kVoiceControlMorphingBarBorderWidth * 2);
                  final double widthExpansion =
                      voiceChannelControlMorphingWidthExpansion(
                        barInnerWidth: barInnerWidth,
                        collapsedBarInnerWidth: collapsedBarInnerWidth,
                        expandedBarInnerWidth: expandedBarInnerWidth,
                      );
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: <Widget>[
                      _VoiceControlSheetDragTarget(
                        key: kVoiceControlSheetDragHeaderKey,
                        onVerticalDragUpdate: (DragUpdateDetails details) {
                          _onVerticalDragUpdate(context, details);
                        },
                        onVerticalDragEnd: (DragEndDetails details) {
                          _onVerticalDragEnd(context, details);
                        },
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: <Widget>[
                            const VoiceChannelControlSheetDragHandle(
                              key: kVoiceControlSheetDragHandleKey,
                            ),
                            VoiceChannelControlBarContent(
                              channelId: widget.channelId,
                              guildId: widget.guildId,
                              connectionId: widget.connectionId,
                              isConnected: widget.isConnected,
                              style: VoiceChannelControlBarStyle.embedded,
                              barInnerWidth: barInnerWidth,
                              expansion: widthExpansion,
                            ),
                          ],
                        ),
                      ),
                      if (showScrollBody)
                        Expanded(
                          child: Listener(
                            behavior: HitTestBehavior.translucent,
                            onPointerMove: (PointerMoveEvent event) {
                              _onPanelPointerMove(context, event);
                            },
                            onPointerUp: (PointerUpEvent event) {
                              _onPanelPointerEnd(context, event);
                            },
                            onPointerCancel: (PointerCancelEvent event) {
                              _onPanelPointerEnd(context, event);
                            },
                            child: ListView(
                              controller: _scrollController,
                              physics: _panelScrollPhysics(),
                              padding: EdgeInsets.zero,
                              children: <Widget>[
                                VoiceChannelControlPanelSettings(
                                  channelId: widget.channelId,
                                ),
                              ],
                            ),
                          ),
                        ),
                    ],
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

class _VoiceControlSheetDragTarget extends StatelessWidget {
  const _VoiceControlSheetDragTarget({
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.child,
    super.key,
  });

  final GestureDragUpdateCallback onVerticalDragUpdate;
  final GestureDragEndCallback onVerticalDragEnd;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onVerticalDragUpdate: onVerticalDragUpdate,
      onVerticalDragEnd: onVerticalDragEnd,
      child: child,
    );
  }
}

class VoiceChannelControlSheetDragHandle extends StatelessWidget {
  const VoiceChannelControlSheetDragHandle({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kVoiceControlSheetHandleHeight,
      width: double.infinity,
      child: Align(
        alignment: Alignment.bottomCenter,
        child: Container(
          width: 36,
          height: 4,
          decoration: BoxDecoration(
            color: context.colors.backgroundModifierAccent,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
      ),
    );
  }
}
