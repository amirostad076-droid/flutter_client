import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/providers/database_provider.dart';

part 'unread_dm_provider.g.dart';

class UnreadDmState {
  final List<DmChannel> channels;

  const UnreadDmState({this.channels = const []});
}

@Riverpod(keepAlive: true)
class UnreadDmChannels extends _$UnreadDmChannels {
  final _removalTimers = <String, Timer>{};
  StreamSubscription<List<DmChannel>>? _subscription;

  @override
  UnreadDmState build() {
    final db = ref.watch(fluxerDatabaseProvider);

    unawaited(_subscription?.cancel());
    _subscription = db.dmChannelDao.watchDmChannels().listen(_reconcile);

    ref.onDispose(() {
      unawaited(_subscription?.cancel());
      for (final timer in _removalTimers.values) {
        timer.cancel();
      }
      _removalTimers.clear();
    });

    return const UnreadDmState();
  }

  void _reconcile(List<DmChannel> allChannels) {
    final unreadChannels =
        allChannels.where((c) => c.unreadCount > 0).toList();
    final unreadIds = unreadChannels.map((c) => c.id).toSet();
    final currentIds = state.channels.map((c) => c.id).toSet();

    // Start removal timers for channels that became read
    for (final id in currentIds) {
      if (!unreadIds.contains(id)) {
        if (!_removalTimers.containsKey(id)) {
          _removalTimers[id] = Timer(const Duration(milliseconds: 750), () {
            _removalTimers.remove(id);
            state = UnreadDmState(
              channels: state.channels.where((c) => c.id != id).toList(),
            );
          });
        }
      }
    }

    // Cancel timers for channels that became unread again
    for (final channel in unreadChannels) {
      _removalTimers[channel.id]?.cancel();
      _removalTimers.remove(channel.id);
    }

    // Merge: keep existing + add new unread
    final merged = <String, DmChannel>{};
    for (final c in state.channels) {
      merged[c.id] = c;
    }
    for (final c in unreadChannels) {
      merged[c.id] = c;
    }

    final newChannels = merged.values.toList()
      ..sort((a, b) => b.lastMessageTime.compareTo(a.lastMessageTime));

    state = UnreadDmState(channels: newChannels);
  }
}
