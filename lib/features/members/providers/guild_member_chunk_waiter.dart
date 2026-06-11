import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

const Duration kGuildMemberChunkWaitTimeout = Duration(milliseconds: 1500);

class GuildMemberChunkWaiter {
  final Map<String, List<Completer<void>>> _pending =
      <String, List<Completer<void>>>{};

  void notifyChunk(String guildId) {
    final List<Completer<void>>? waiters = _pending.remove(guildId);
    if (waiters == null) {
      return;
    }
    for (final Completer<void> completer in waiters) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }
  }

  Future<void> waitForChunk(
    String guildId, {
    Duration timeout = kGuildMemberChunkWaitTimeout,
  }) async {
    final Completer<void> completer = Completer<void>();
    _pending.putIfAbsent(guildId, () => <Completer<void>>[]).add(completer);
    try {
      await completer.future.timeout(timeout);
    } on TimeoutException {
      return;
    } finally {
      final List<Completer<void>>? waiters = _pending[guildId];
      waiters?.remove(completer);
      if (waiters != null && waiters.isEmpty) {
        _pending.remove(guildId);
      }
    }
  }
}

final Provider<GuildMemberChunkWaiter> guildMemberChunkWaiterProvider =
    Provider<GuildMemberChunkWaiter>((Ref ref) {
      ref.keepAlive();
      return GuildMemberChunkWaiter();
    });
