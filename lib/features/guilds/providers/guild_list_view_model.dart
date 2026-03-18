import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/guilds/providers/guild_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_list_view_model.g.dart';

class GuildListViewState {
  static const _unset = Object();

  final List<Guild> guilds;
  final bool isLoading;
  final String? errorMessage;

  const GuildListViewState({
    required this.guilds,
    required this.isLoading,
    required this.errorMessage,
  });

  GuildListViewState copyWith({
    List<Guild>? guilds,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return GuildListViewState(
      guilds: guilds ?? this.guilds,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
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
        state = state.copyWith(guilds: guilds, isLoading: false);
      },
      onError: (Object error) {
        debugPrint('[GuildListViewModel] Watch error: $error');
      },
    );

    ref.onDispose(() => _subscription?.cancel());

    unawaited(Future<void>.microtask(_loadGuilds));
    return const GuildListViewState(
      guilds: [],
      isLoading: true,
      errorMessage: null,
    );
  }

  Future<void> _loadGuilds() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(guildRepositoryProvider).getServers();
    } on Exception catch (e) {
      debugPrint('[GuildListViewModel] Failed to load guilds: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load guilds',
      );
    }
  }

  Future<void> refresh() => _loadGuilds();
}
