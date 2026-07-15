import 'dart:async' show unawaited;
import 'dart:math' as math;

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
      _ChatExpressionExpandableSheetState();
}

class _ChatExpressionExpandableSheetState
    extends ConsumerState<ChatExpressionExpandableSheet>
    with TickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  late double _height;
  bool _isDraggingViaScroll = false;
  bool _isPullingFromContent = false;
  bool _initialized = false;
  bool _allowScrollResize = false;
  int? _resizePointerId;
  AnimationController? _snapController;
  Animation<double>? _snapAnimation;

  @override
  void initState() {
    super.initState();
    _height = widget.collapsedHeight;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _allowScrollResize = true;
    });
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
    _disposeSnapController();
    _scrollController.dispose();
    super.dispose();
  }

  double get _minHeight => widget.collapsedHeight;

  double get _maxHeight =>
      MediaQuery.sizeOf(context).height *
          kInlineExpressionPanelMaxScreenFraction -
      widget.dragHandleHeight;

  double get _totalHeight => inlineExpressionPanelDockedTotalHeight(
    contentHeight: _height,
    dragHandleHeight: widget.dragHandleHeight,
  );

  bool get _isExpanded => _height >= _expandedHeight - 1;

  bool get _isResizing => _resizePointerId != null;

  double get _expandedHeight {
    final MediaQueryData mediaQuery = MediaQuery.of(context);
    final double screenHeight = mediaQuery.size.height;
    final double totalExpanded = math.min(
      inlineExpressionPanelExpandedHeight(
        availableHeight: screenHeight * kInlineExpressionPanelMaxScreenFraction,
        screenHeight: screenHeight,
        keyboardInset: mediaQuery.viewInsets.bottom,
        topPadding: mediaQuery.viewPadding.top + kMobileChannelHeaderHeight,
        topMargin: context.layout.s2,
        viewPaddingBottom: mediaQuery.viewPadding.bottom,
      ),
      MediaQuery.sizeOf(context).height *
          kInlineExpressionPanelMaxScreenFraction,
    );
    return math.max(_minHeight, totalExpanded - widget.dragHandleHeight);
  }

  void _ensureInitialized() {
    if (_initialized) {
      return;
    }
    _height = widget.collapsedHeight;
    _initialized = true;
  }

  void _disposeSnapController() {
    _snapController?.dispose();
    _snapController = null;
    _snapAnimation = null;
  }

  void _adjustSheetHeight(double deltaDy) {
    final double nextHeight = (_height - deltaDy).clamp(_minHeight, _maxHeight);
    if ((nextHeight - _height).abs() < 0.5) {
      return;
    }
    setState(() => _height = nextHeight);
  }

  void _onSheetPointerDown(PointerDownEvent event) {
    if (event.localPosition.dy > widget.dragHandleHeight) {
      return;
    }
    _disposeSnapController();
    _resizePointerId = event.pointer;
    setState(() {});
  }

  void _onSheetPointerMove(PointerMoveEvent event) {
    if (event.pointer == _resizePointerId) {
      _adjustSheetHeight(event.delta.dy);
      return;
    }
  }

  void _onSheetPointerEnd(PointerEvent event) {
    if (event.pointer == _resizePointerId) {
      setState(() => _resizePointerId = null);
      _snapAfterInteractiveResize();
    }
  }

  void _onContentPointerMove(PointerMoveEvent event) {
    if (_isResizing || _resizePointerId != null) {
      return;
    }
    if (!inlineExpressionPanelControllerIsAtTop(_scrollController) ||
        event.delta.dy <= 0) {
      return;
    }
    _disposeSnapController();
    _isPullingFromContent = true;
    _adjustSheetHeight(event.delta.dy);
  }

  void _onContentPointerEnd(PointerEvent event) {
    if (!_isPullingFromContent) {
      return;
    }
    _isPullingFromContent = false;
    _snapAfterInteractiveResize();
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
        _closePanel();
      case InlineExpressionPanelSnapTarget.anchor:
        _animateToHeight(widget.collapsedHeight);
      case InlineExpressionPanelSnapTarget.expanded:
        _animateToHeight(_expandedHeight);
    }
  }

  void _snapAfterInteractiveResize() {
    _snapFromVelocity(0);
  }

  void _animateToHeight(double target) {
    final double clampedTarget = target.clamp(_minHeight, _maxHeight);
    if ((_height - clampedTarget).abs() < 1) {
      setState(() => _height = clampedTarget);
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
      return;
    }
    _disposeSnapController();
    _snapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    );
    _snapAnimation =
        Tween<double>(begin: _height, end: clampedTarget).animate(
          CurvedAnimation(parent: _snapController!, curve: Curves.easeOutCubic),
        )..addListener(() {
          if (!mounted) {
            return;
          }
          setState(() => _height = _snapAnimation!.value);
        });
    _snapController!.addStatusListener((AnimationStatus status) {
      if (status != AnimationStatus.completed || !mounted) {
        return;
      }
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
      _disposeSnapController();
      setState(() {});
    });
    unawaited(_snapController!.forward());
  }

  void _closePanel() {
    _disposeSnapController();
    setState(() {
      _resizePointerId = null;
      _isPullingFromContent = false;
      _height = widget.collapsedHeight;
    });
    ref.read(expressionPanelProvider.notifier).close();
  }

  void _shrinkFromScrollPull(double delta) {
    if (delta >= 0 || _height <= _minHeight + 0.5) {
      return;
    }
    _disposeSnapController();
    _isDraggingViaScroll = true;
    setState(() {
      _height = (_height + delta).clamp(_minHeight, _maxHeight);
    });
  }

  bool _onScrollNotification(ScrollNotification notification) {
    if (!_allowScrollResize || _isResizing) {
      return false;
    }
    final double maxHeight = _maxHeight;
    if (notification is ScrollUpdateNotification) {
      final double delta = notification.scrollDelta ?? 0;
      if (inlineExpressionPanelScrollIsAtTop(notification.metrics) &&
          delta < 0) {
        _shrinkFromScrollPull(delta);
        return true;
      }
      if (!_isExpanded &&
          delta > 0 &&
          inlineExpressionPanelScrollIsAtTop(notification.metrics)) {
        _isDraggingViaScroll = true;
        _disposeSnapController();
        setState(() {
          _height = (_height + delta).clamp(_minHeight, maxHeight);
        });
        return true;
      }
    }
    if (notification is OverscrollNotification) {
      final double delta = notification.overscroll;
      if (inlineExpressionPanelShouldHandleTopOverscroll(
        notification.metrics,
        delta,
      )) {
        _shrinkFromScrollPull(delta);
        return true;
      }
      if (!_isExpanded && delta > 0) {
        _isDraggingViaScroll = true;
        _disposeSnapController();
        setState(() {
          _height = (_height + delta).clamp(_minHeight, maxHeight);
        });
        return true;
      }
    }
    if (notification is ScrollEndNotification && _isDraggingViaScroll) {
      _isDraggingViaScroll = false;
      _snapAfterInteractiveResize();
      return true;
    }
    return false;
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
    final Widget sheetBody = SizedBox(
      height: _totalHeight,
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
          child: Listener(
            key: kChatExpressionSheetDragHeaderKey,
            behavior: HitTestBehavior.translucent,
            onPointerDown: _onSheetPointerDown,
            onPointerMove: _onSheetPointerMove,
            onPointerUp: _onSheetPointerEnd,
            onPointerCancel: _onSheetPointerEnd,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                SizedBox(
                  key: kChatExpressionSheetDragHandleKey,
                  height: widget.dragHandleHeight,
                  width: double.infinity,
                  child: const IgnorePointer(
                    child: FluxerBottomSheetDragHandle(
                      includeTopPadding: false,
                    ),
                  ),
                ),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.translucent,
                    onPointerMove: _onContentPointerMove,
                    onPointerUp: _onContentPointerEnd,
                    onPointerCancel: _onContentPointerEnd,
                    child: AbsorbPointer(
                      absorbing: _isResizing,
                      child: ScrollConfiguration(
                        behavior: ScrollConfiguration.of(context).copyWith(
                          physics: inlineExpressionPanelScrollPhysics(),
                        ),
                        child: NotificationListener<ScrollNotification>(
                          onNotification: _onScrollNotification,
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
                                          _animateToHeight(
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
