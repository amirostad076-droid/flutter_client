import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/chat/providers/slowmode_immunity_provider.dart';
import 'package:fluxer_app/features/chat/providers/slowmode_tracker.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'slowmode_blocked_provider.g.dart';

@riverpod
Stream<bool> isSlowmodeBlocked(Ref ref, String channelId) async* {
  if (channelId.isEmpty) {
    yield false;
    return;
  }
  final channel = await ref.watch(channelByIdProvider(channelId).future);
  final rate = channel?.rateLimitPerUser ?? 0;
  final isImmune = await ref.watch(isSlowmodeImmuneProvider(channelId).future);
  ref.watch(slowmodeTrackerProvider);
  if (rate <= 0 || isImmune) {
    yield false;
    return;
  }
  Duration remaining() =>
      ref.read(slowmodeTrackerProvider.notifier).remainingFor(channelId, rate);
  while (remaining() > Duration.zero) {
    yield true;
    await Future<void>.delayed(const Duration(seconds: 1));
  }
  yield false;
}
