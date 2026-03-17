import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/guilds/providers/guild_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_list_view_model.g.dart';

class GuildListViewState {
  static const _unset = Object();

  final List<Guild> guilds;
  final String? selectedGuildId;
  final bool isDmActive;
  final bool isFavoritesActive;
  final bool isLoading;
  final String? errorMessage;

  const GuildListViewState({
    required this.guilds,
    required this.selectedGuildId,
    required this.isDmActive,
    required this.isFavoritesActive,
    required this.isLoading,
    required this.errorMessage,
  });

  GuildListViewState copyWith({
    List<Guild>? guilds,
    String? selectedGuildId,
    bool? isDmActive,
    bool? isFavoritesActive,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return GuildListViewState(
      guilds: guilds ?? this.guilds,
      selectedGuildId: selectedGuildId ?? this.selectedGuildId,
      isDmActive: isDmActive ?? this.isDmActive,
      isFavoritesActive: isFavoritesActive ?? this.isFavoritesActive,
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
      selectedGuildId: null,
      isDmActive: true,
      isFavoritesActive: false,
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

  void selectGuild(String guildId) {
    state = state.copyWith(
      selectedGuildId: guildId,
      isDmActive: false,
      isFavoritesActive: false,
    );
  }

  void setDmActive() {
    state = state.copyWith(isDmActive: true, isFavoritesActive: false);
  }

  void setFavoritesActive() {
    state = state.copyWith(isFavoritesActive: true, isDmActive: false);
  }

  Future<void> refresh() => _loadGuilds();
}
