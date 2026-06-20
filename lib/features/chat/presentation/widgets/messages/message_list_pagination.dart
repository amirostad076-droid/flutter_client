import 'dart:async';

import 'package:flutter/material.dart';

const double kMessageListLoadMoreThreshold = 200;
const double kMessageListLoadNewerThreshold = 200;
const Duration kMessageListPaginationCooldown = Duration(milliseconds: 300);

/// Guards bidirectional message list pagination triggers.
class MessageListPaginationGuard {
  MessageListPaginationGuard({
    ScrollController? scrollController,
    bool Function()? isProgrammaticScroll,
  }) : _scrollController = scrollController,
       _isProgrammaticScroll = isProgrammaticScroll;

  final ScrollController? _scrollController;
  final bool Function()? _isProgrammaticScroll;
  bool _paginationCooldown = false;
  Timer? _cooldownTimer;
  double? _lastScrollPixels;

  bool get isOnCooldown => _paginationCooldown;

  void dispose() {
    _cooldownTimer?.cancel();
  }

  void beginCooldown() {
    _paginationCooldown = true;
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer(kMessageListPaginationCooldown, () {
      _paginationCooldown = false;
    });
  }

  void resetScrollIntent() {
    _lastScrollPixels = null;
    _paginationCooldown = false;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
  }

  void seedScrollPixels(double pixels) {
    _lastScrollPixels = pixels;
  }

  bool shouldHandleScroll({
    required bool isLoadingMore,
    required bool isLoadingNewer,
    bool bypassCooldown = false,
  }) {
    if (isLoadingMore || isLoadingNewer) {
      return false;
    }
    if (!bypassCooldown && _paginationCooldown) {
      return false;
    }
    final ScrollController? controller = _scrollController;
    return controller != null && controller.hasClients;
  }

  bool shouldLoadMore({
    required bool hasMoreMessages,
    required bool isLoadingMore,
    required bool isLoadingNewer,
    bool requireUserIntent = true,
    bool bypassCooldown = false,
  }) {
    if (!shouldHandleScroll(
      isLoadingMore: isLoadingMore,
      isLoadingNewer: isLoadingNewer,
      bypassCooldown: bypassCooldown,
    )) {
      return false;
    }
    if (!hasMoreMessages) {
      return false;
    }
    final ScrollPosition position = _scrollController!.position;
    if (requireUserIntent && !hasUserScrollIntent(position)) {
      return false;
    }
    return position.pixels >=
        position.maxScrollExtent - kMessageListLoadMoreThreshold;
  }

  bool shouldLoadNewer({
    required bool hasMoreNewerMessages,
    required bool isLoadingMore,
    required bool isLoadingNewer,
    bool requireUserIntent = true,
    bool bypassCooldown = false,
  }) {
    if (!shouldHandleScroll(
      isLoadingMore: isLoadingMore,
      isLoadingNewer: isLoadingNewer,
      bypassCooldown: bypassCooldown,
    )) {
      return false;
    }
    if (!hasMoreNewerMessages) {
      return false;
    }
    final ScrollPosition position = _scrollController!.position;
    if (requireUserIntent && !hasUserScrollIntent(position)) {
      return false;
    }
    return position.pixels <=
        position.minScrollExtent + kMessageListLoadNewerThreshold;
  }

  bool hasUserScrollIntent(ScrollPosition position) {
    return _hasUserScrollIntent(position);
  }

  bool _hasUserScrollIntent(ScrollPosition position) {
    if (_isProgrammaticScroll?.call() ?? false) {
      return false;
    }
    if (position.isScrollingNotifier.value) {
      _lastScrollPixels = position.pixels;
      return true;
    }
    final double? previousPixels = _lastScrollPixels;
    _lastScrollPixels = position.pixels;
    if (previousPixels == null) {
      return false;
    }
    return (position.pixels - previousPixels).abs() >= 1;
  }
}
