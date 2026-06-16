import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/gateway/providers/gateway_event_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_typing_provider.g.dart';

/// Whether another user is currently typing in [channelId].
///
/// Row-scoped replacement for watching the whole [typingIndicatorsProvider]
/// list from each sidebar tile: only rows whose boolean flips rebuild.
@riverpod
bool channelHasTyping(Ref ref, String channelId) {
  final String? currentUserId = ref.watch(currentUserIdProvider);
  final List<TypingUser> entries = ref.watch(typingIndicatorsProvider);
  final DateTime now = DateTime.now();
  return entries.any(
    (TypingUser t) =>
        t.channelId == channelId &&
        t.userId != currentUserId &&
        t.expiresAt.isAfter(now),
  );
}
