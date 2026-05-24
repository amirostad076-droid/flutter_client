import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_availability_provider.g.dart';

@Riverpod(keepAlive: true)
class GuildAvailability extends _$GuildAvailability {
  @override
  Set<String> build() => {};

  void loadFromReady(List<Map<String, dynamic>> rawGuilds) {
    state = {
      for (final rawGuild in rawGuilds)
        if (_isTrackedUnavailable(rawGuild)) rawGuild['id'] as String,
    };
  }

  void handleGuildAvailability(
    String guildId, {
    required bool unavailable,
    bool unavailableHidden = false,
  }) {
    if (unavailable && !unavailableHidden) {
      state = {...state, guildId};
      return;
    }
    if (state.contains(guildId)) {
      state = Set.of(state)..remove(guildId);
    }
  }

  void setGuildAvailable(String guildId) {
    if (state.contains(guildId)) {
      state = Set.of(state)..remove(guildId);
    }
  }

  void clear() {
    state = {};
  }

  bool _isTrackedUnavailable(Map<String, dynamic> rawGuild) {
    final unavailable = rawGuild['unavailable'] as bool? ?? false;
    if (!unavailable) {
      return false;
    }
    return !(rawGuild['unavailable_hidden'] as bool? ?? false);
  }
}
