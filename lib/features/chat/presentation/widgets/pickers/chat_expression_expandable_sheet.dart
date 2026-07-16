import 'dart:async';

import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/inline_expression_panel.dart';
import 'package:fluxer_app/features/chat/providers/pickers/bottom_input_slot_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/expression_panel_provider.dart';
import 'package:fluxer_app/features/chat/utils/bottom_input_slot_layout.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_layout.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_scroll_physics.dart';
import 'package:fluxer_app/features/ui/bottom_sheet/fluxer_bottom_sheet.dart';
import 'package:fluxer_app/shared/gestures/expandable_sheet_gestures.dart';
import 'package:fluxer_app/shared/gestures/nested_horizontal_scrollable.dart';

const Key kChatExpressionSheetKey = kExpressionPanelShellGestureBlockKey;
const Key kChatExpressionSheetDragHandleKey = Key(
  'chat-expression-sheet-drag-handle',
);
const Key kChatExpressionSheetDragHeaderKey = Key(
  'chat-expression-sheet-drag-header',
);

class ChatExpressionExpandableSheet extends ConsumerStatefulWidget {
  const ChatExpressionExpandableSheet({
    required this.collapsedHeight,
    required this.dragHandleHeight,
    required this.parentHeight,
    this.contentBuilder,
    super.key,
  });

  final double collapsedHeight;
  final double dragHandleHeight;
  final double parentHeight;
  final Widget Function(
    BuildContext context,
    ScrollController scrollController,
  )?
  contentBuilder;

  @override
  ConsumerState<ChatExpressionExpandableSheet> createState() =>
      ChatExpressionExpandableSheetState();
}

class ChatExpressionExpandableSheetState
    extends ConsumerState<ChatExpressionExpandableSheet> {
  final ScrollController _scrollController = ScrollController();
  final VelocityTracker _contentVelocityTracker = VelocityTracker.withKind(
    PointerDeviceKind.touch,
  );
  late double _height;
  bool _isDragging = false;
  bool? _dragWasPastCollapsed;
  bool _initialized = false;
  bool _isClosing = false;
  Timer? _closeTimer;

  @override
  void initState() {
    super.initState();
    _height = widget.collapsedHeight;
  }

  @override
  void didUpdateWidget(ChatExpressionExpandableSheet oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.collapsedHeight != widget.collapsedHeight &&
        !_isExpanded &&
        (_height - oldWidget.collapsedHeight).abs() < 1) {
      _height = widget.collapsedHeight;
    }
  }

  @override
  void dispose() {
    _closeTimer?.cancel();
    _scrollController.dispose();
    super.dispose();
  }

  double get _minHeight => widget.collapsedHeight;

  double get _expandedHeight {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double totalExpanded = inlineExpressionPanelExpandedHeight(
      availableHeight: screenHeight * kInlineExpressionPanelMaxScreenFraction,
      screenHeight: screenHeight,
      keyboardInset: mediaQuery.viewInsets.bottom,
      topPadding: mediaQuery.viewPadding.top + kMobileChannelHeaderHeight,
      topMargin: context.layout.s2,
      viewPaddingBottom: mediaQuery.viewPadding.bottom,
    ).clamp(0, screenHeight * kInlineExpressionPanelMaxScreenFraction);
    return totalExpanded - widget.dragHandleHeight;
  }

  double get _maxHeight => _expandedHeight;

  double get _totalHeight {
    if (_height <= 0) {
      return 0;
    }
    return inlineExpressionPanelDockedTotalHeight(
      contentHeight: _height,
      dragHandleHeight: widget.dragHandleHeight,
    );
  }

  bool get _isExpanded => _height >= _expandedHeight - 1;

  void _ensureInitialized() {
    if (_initialized) {
      return;
    }
    _height = widget.collapsedHeight;
    _initialized = true;
  }

  void _adjustSheetHeight(double deltaDy) {
    final double collapsed = _minHeight;
    final double expanded = _maxHeight;
    final double previousHeight = _height;
    final double nextHeight = (previousHeight - deltaDy).clamp(
      collapsed,
      expanded,
    );
    setState(() {
      _isDragging = true;
      _height = nextHeight;
    });
    _dragWasPastCollapsed = updateExpandableSheetDragHaptic(
      wasPastCollapsed: _dragWasPastCollapsed,
      previousHeight: previousHeight,
      currentHeight: nextHeight,
      collapsedHeight: collapsed,
    );
  }

  void _resetDragHaptics() {
    _dragWasPastCollapsed = null;
  }

  void _onHeaderDragUpdate(DragUpdateDetails details) {
    _adjustSheetHeight(details.delta.dy);
  }

  void _onHeaderDragEnd(DragEndDetails details) {
    _snapFromVelocity(details.primaryVelocity ?? 0);
  }

  void _onContentPointerDown(PointerDownEvent event) {
    _contentVelocityTracker.addPosition(event.timeStamp, event.position);
  }

  void _onContentPointerMove(PointerMoveEvent event) {
    _contentVelocityTracker.addPosition(event.timeStamp, event.position);
    if (!_isExpanded && event.delta.dy < 0) {
      return;
    }
    if (!inlineExpressionPanelControllerIsAtTop(_scrollController)) {
      return;
    }
    if (event.delta.dy > 0) {
      _adjustSheetHeight(event.delta.dy);
    }
  }

  void _onContentPointerEnd(PointerEvent event) {
    if (!_isDragging) {
      return;
    }
    final double velocity = _contentVelocityTracker
        .getVelocity()
        .pixelsPerSecond
        .dy;
    _snapFromVelocity(velocity);
  }

  void _snapFromVelocity(double velocity) {
    final InlineExpressionPanelSnapTarget target =
        inlineExpressionPanelSnapTarget(
          currentHeight: _height,
          velocity: velocity,
          anchorHeight: widget.collapsedHeight,
          expandedHeight: _expandedHeight,
        );
    switch (target) {
      case InlineExpressionPanelSnapTarget.close:
        _beginCloseAnimation();
      case InlineExpressionPanelSnapTarget.anchor:
        _snapToHeight(widget.collapsedHeight);
      case InlineExpressionPanelSnapTarget.expanded:
        _snapToHeight(_expandedHeight);
    }
  }

  void _snapToHeight(double target) {
    final double clampedTarget = target.clamp(_minHeight, _maxHeight);
    setState(() {
      _isDragging = false;
      _height = clampedTarget;
    });
    _resetDragHaptics();
    if (clampedTarget <= widget.collapsedHeight + 1) {
      ref
          .read(bottomInputSlotProvider.notifier)
          .settlePanelHeight(
            inlineExpressionPanelDockedTotalHeight(
              contentHeight: clampedTarget,
              dragHandleHeight: widget.dragHandleHeight,
            ),
          );
    }
  }

  void _beginCloseAnimation() {
    _closeTimer?.cancel();
    setState(() {
      _isDragging = false;
      _isClosing = true;
      _height = 0;
    });
    _resetDragHaptics();
    playExpandableSheetDismissHaptic();
    _closeTimer = Timer(
      expandableSheetSnapDuration(context, isDragging: false),
      () {
        if (!mounted) {
          return;
        }
        setState(() => _isClosing = false);
        ref.read(expressionPanelProvider.notifier).close();
      },
    );
  }

  void _closePanel() {
    _beginCloseAnimation();
  }

  @visibleForTesting
  void closeForTest() {
    _beginCloseAnimation();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.parentHeight <= 0 || widget.collapsedHeight <= 0) {
      return const SizedBox.shrink();
    }
    _ensureInitialized();
    final colors = context.colors;
    final double homeIndicatorInset = inlineExpressionPanelHomeIndicatorInset(
      MediaQuery.of(context),
    );
    final Duration animationDuration = expandableSheetSnapDuration(
      context,
      isDragging: _isDragging,
    );
    final Widget sheetBody = AnimatedContainer(
      duration: animationDuration,
      curve: Curves.easeOutCubic,
      height: _totalHeight,
      child: ClipRect(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: colors.backgroundSecondary,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            boxShadow: const <BoxShadow>[
              BoxShadow(
                color: Color.fromRGBO(0, 0, 0, 0.15),
                blurRadius: 12,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: _totalHeight <= 0 || _isClosing
                  ? const <Widget>[]
                  : <Widget>[
                      ExpandableSheetDragTarget(
                        key: kChatExpressionSheetDragHeaderKey,
                        onVerticalDragUpdate: _onHeaderDragUpdate,
                        onVerticalDragEnd: _onHeaderDragEnd,
                        child: SizedBox(
                          key: kChatExpressionSheetDragHandleKey,
                          height: widget.dragHandleHeight,
                          width: double.infinity,
                          child: const IgnorePointer(
                            child: FluxerBottomSheetDragHandle(
                              includeTopPadding: false,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: Listener(
                          behavior: HitTestBehavior.translucent,
                          onPointerDown: _onContentPointerDown,
                          onPointerMove: _onContentPointerMove,
                          onPointerUp: _onContentPointerEnd,
                          onPointerCancel: _onContentPointerEnd,
                          child: ScrollConfiguration(
                            behavior: ScrollConfiguration.of(context).copyWith(
                              physics:
                                  inlineExpressionPanelContentScrollPhysics(
                                    isSheetExpanded: _isExpanded,
                                  ),
                            ),
                            child: RepaintBoundary(
                              child:
                                  widget.contentBuilder?.call(
                                    context,
                                    _scrollController,
                                  ) ??
                                  ExpressionPanelContent(
                                    scrollController: _scrollController,
                                    onClose: _closePanel,
                                    onEmojiSelect:
                                        (String name, String surrogates) {
                                          ref
                                              .read(
                                                pendingEmojiInsertProvider
                                                    .notifier,
                                              )
                                              .emit(name, surrogates);
                                          if (_isExpanded) {
                                            _snapToHeight(
                                              widget.collapsedHeight,
                                            );
                                          }
                                        },
                                    onGifSelect: (selection) => ref
                                        .read(
                                          pendingGifSelectionProvider.notifier,
                                        )
                                        .emit(selection),
                                    onStickerSelect: (selection) => ref
                                        .read(
                                          pendingStickerSelectionProvider
                                              .notifier,
                                        )
                                        .emit(selection),
                                    onFavoriteMemeSelect: (selection) => ref
                                        .read(
                                          pendingFavoriteMemeSelectionProvider
                                              .notifier,
                                        )
                                        .emit(selection),
                                  ),
                            ),
                          ),
                        ),
                      ),
                    ],
            ),
          ),
        ),
      ),
    );
    if (homeIndicatorInset <= 0) {
      return ColoredBox(
        key: kChatExpressionSheetKey,
        color: colors.backgroundSecondary,
        child: sheetBody,
      );
    }
    return Column(
      key: kChatExpressionSheetKey,
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: <Widget>[
        sheetBody,
        ColoredBox(
          color: colors.backgroundSecondary,
          child: SizedBox(height: homeIndicatorInset),
        ),
      ],
    );
  }
}
