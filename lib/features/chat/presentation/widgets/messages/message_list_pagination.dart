import 'dart:async';

import 'package:flutter/material.dart';

const double kMessageListLoadMoreThreshold = 200;
const double kMessageListLoadNewerThreshold = 200;
const Duration kMessageListPaginationCooldown = Duration(milliseconds: 300);

/// Guards bidirectional message list pagination triggers.
class MessageListPaginationGuard {
  MessageListPaginationGuard({ScrollController? scrollController})
    : _scrollController = scrollController;

  final ScrollController? _scrollController;
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

  bool shouldHandleScroll({
    required bool isLoadingMore,
    required bool isLoadingNewer,
  }) {
    if (_paginationCooldown || isLoadingMore || isLoadingNewer) {
      return false;
    }
    final ScrollController? controller = _scrollController;
    return controller != null && controller.hasClients;
  }

  bool shouldLoadMore({
    required bool hasMoreMessages,
    required bool isLoadingMore,
    required bool isLoadingNewer,
  }) {
    if (!shouldHandleScroll(
      isLoadingMore: isLoadingMore,
      isLoadingNewer: isLoadingNewer,
    )) {
      return false;
    }
    if (!hasMoreMessages) {
      return false;
    }
    final ScrollPosition position = _scrollController!.position;
    if (!_hasUserScrollIntent(position)) {
      return false;
    }
    return position.pixels >=
        position.maxScrollExtent - kMessageListLoadMoreThreshold;
  }

  bool shouldLoadNewer({
    required bool hasMoreNewerMessages,
    required bool isLoadingMore,
    required bool isLoadingNewer,
  }) {
    if (!shouldHandleScroll(
      isLoadingMore: isLoadingMore,
      isLoadingNewer: isLoadingNewer,
    )) {
      return false;
    }
    if (!hasMoreNewerMessages) {
      return false;
    }
    final ScrollPosition position = _scrollController!.position;
    if (!_hasUserScrollIntent(position)) {
      return false;
    }
    return position.pixels <= kMessageListLoadNewerThreshold;
  }

  bool _hasUserScrollIntent(ScrollPosition position) {
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
