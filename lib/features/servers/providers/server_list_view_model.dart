import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/servers/domain/server.dart';
import 'package:fluxeron/features/servers/providers/server_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_list_view_model.g.dart';

class ServerListViewState {
  static const _unset = Object();

  final List<Server> servers;
  final String? selectedServerId;
  final bool isDmActive;
  final bool isFavoritesActive;
  final bool isLoading;
  final String? errorMessage;

  const ServerListViewState({
    required this.servers,
    required this.selectedServerId,
    required this.isDmActive,
    required this.isFavoritesActive,
    required this.isLoading,
    required this.errorMessage,
  });

  ServerListViewState copyWith({
    List<Server>? servers,
    String? selectedServerId,
    bool? isDmActive,
    bool? isFavoritesActive,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return ServerListViewState(
      servers: servers ?? this.servers,
      selectedServerId: selectedServerId ?? this.selectedServerId,
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
class ServerListViewModel extends _$ServerListViewModel {
  StreamSubscription<List<Server>>? _subscription;

  @override
  ServerListViewState build() {
    final repo = ref.watch(serverRepositoryProvider);

    unawaited(_subscription?.cancel());
    _subscription = repo.watchServers().listen(
      (servers) {
        state = state.copyWith(servers: servers, isLoading: false);
      },
      onError: (Object error) {
        debugPrint('[ServerListViewModel] Watch error: $error');
      },
    );

    ref.onDispose(() => _subscription?.cancel());

    unawaited(Future<void>.microtask(_loadServers));
    return const ServerListViewState(
      servers: [],
      selectedServerId: null,
      isDmActive: true,
      isFavoritesActive: false,
      isLoading: true,
      errorMessage: null,
    );
  }

  Future<void> _loadServers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      await ref.read(serverRepositoryProvider).getServers();
    } on Exception catch (e) {
      debugPrint('[ServerListViewModel] Failed to load servers: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load servers',
      );
    }
  }

  void selectServer(String serverId) {
    state = state.copyWith(
      selectedServerId: serverId,
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

  Future<void> refresh() => _loadServers();
}
