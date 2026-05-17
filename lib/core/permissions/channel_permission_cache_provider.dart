import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_permission_cache_provider.g.dart';

/// Precomputed effective permission bitfields per guild channel, refreshed
/// from gateway events.
@Riverpod(keepAlive: true)
class ChannelPermissionCache extends _$ChannelPermissionCache {
  @override
  Map<String, int> build() => {};

  /// Cached bits for [channelId], or `null` when not resolved yet.
  int? getChannelBits(String channelId) => state[channelId];

  Future<void> rebuildChannel(String channelId) async {
    if (channelId.isEmpty) {
      return;
    }
    final ChannelPermissionBitsOutcome outcome =
        await computeEffectiveGuildChannelPermissionBitsOutcome(
          ref: ref,
          channelId: channelId,
        );
    if (!outcome.shouldCache) {
      evictChannel(channelId);
      return;
    }
    final Map<String, int> next = Map<String, int>.from(state);
    next[channelId] = outcome.value;
    state = next;
  }

  Future<void> rebuildGuild(String guildId) async {
    if (guildId.isEmpty) {
      return;
    }
    final db = ref.read(fluxerDatabaseProvider);
    final channels = await db.channelDao.getChannels(guildId);
    for (final channel in channels) {
      await rebuildChannel(channel.id);
    }
  }

  Future<void> rebuildAll() async {
    final db = ref.read(fluxerDatabaseProvider);
    final channels = await db.channelDao.getAllChannels();
    for (final channel in channels) {
      if (channel.guildId.isNotEmpty) {
        await rebuildChannel(channel.id);
      }
    }
  }

  void evictChannel(String channelId) {
    if (!state.containsKey(channelId)) {
      return;
    }
    final Map<String, int> next = Map<String, int>.from(state)
      ..remove(channelId);
    state = next;
  }

  Future<void> evictGuild(String guildId) async {
    if (guildId.isEmpty || state.isEmpty) {
      return;
    }
    final db = ref.read(fluxerDatabaseProvider);
    final channels = await db.channelDao.getChannels(guildId);
    final Map<String, int> next = Map<String, int>.from(state);
    for (final channel in channels) {
      next.remove(channel.id);
    }
    state = next;
  }

  void clearAll() {
    if (state.isEmpty) {
      return;
    }
    state = {};
  }
}
