import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_event_providers.g.dart';

class TypingUser {
  final String userId;
  final String channelId;
  final DateTime expiresAt;

  const TypingUser({
    required this.userId,
    required this.channelId,
    required this.expiresAt,
  });
}

@Riverpod(keepAlive: true)
class TypingIndicators extends _$TypingIndicators {
  Timer? _cleanupTimer;

  @override
  List<TypingUser> build() {
    _cleanupTimer = Timer.periodic(
      const Duration(seconds: 2),
      (_) => _cleanup(),
    );
    ref.onDispose(() => _cleanupTimer?.cancel());
    return const [];
  }

  void addTyping(String channelId, String userId) {
    final expiresAt = DateTime.now().add(const Duration(seconds: 8));

    state = [
      ...state.where((t) => !(t.channelId == channelId && t.userId == userId)),
      TypingUser(userId: userId, channelId: channelId, expiresAt: expiresAt),
    ];
  }

  List<TypingUser> typingInChannel(String channelId) {
    final now = DateTime.now();
    return state
        .where((t) => t.channelId == channelId && t.expiresAt.isAfter(now))
        .toList();
  }

  void _cleanup() {
    final now = DateTime.now();
    final updated = state.where((t) => t.expiresAt.isAfter(now)).toList();
    if (updated.length != state.length) {
      state = updated;
    }
  }
}
