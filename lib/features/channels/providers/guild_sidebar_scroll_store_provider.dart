import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_sidebar_scroll_store_provider.g.dart';

/// Non-reactive holder of per-guild channel-list scroll offsets, used to
/// restore the sidebar scroll position when switching between guilds.
///
/// Read/write via `ref.read` only; never watched. Offsets are in-session and
/// reset on app restart.
class GuildSidebarScrollStore {
  final Map<String, double> _offsets = <String, double>{};

  double? offsetFor(String guildId) => _offsets[guildId];

  void setOffset(String guildId, double offset) => _offsets[guildId] = offset;
}

@Riverpod(keepAlive: true)
GuildSidebarScrollStore guildSidebarScrollStore(Ref ref) =>
    GuildSidebarScrollStore();
