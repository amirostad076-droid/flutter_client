import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/guilds/providers/guild_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_list_view_model.g.dart';

class GuildListViewState {
  final List<Guild> guilds;

  const GuildListViewState({required this.guilds});

  GuildListViewState copyWith({List<Guild>? guilds}) {
    return GuildListViewState(guilds: guilds ?? this.guilds);
  }
}

@Riverpod(keepAlive: true)
class GuildListViewModel extends _$GuildListViewModel {
  StreamSubscription<List<Guild>>? _subscription;

  @override
  GuildListViewState build() {
    final repo = ref.watch(guildRepositoryProvider);

    unawaited(_subscription?.cancel());
    _subscription = repo.watchServers().listen(
      (guilds) {
        state = state.copyWith(guilds: guilds);
      },
      onError: (Object error) {
        debugPrint('[GuildListViewModel] Watch error: $error');
      },
    );

    ref.onDispose(() => _subscription?.cancel());

    return const GuildListViewState(guilds: []);
  }
}
