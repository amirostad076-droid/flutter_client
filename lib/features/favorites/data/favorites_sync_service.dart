import 'dart:async';

import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/synced_preferences/favorites_state_codec.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_sync_service.g.dart';

const Duration _kFavoritesSyncDebounce = Duration(milliseconds: 500);

@Riverpod(keepAlive: true)
FavoritesSyncService favoritesSyncService(Ref ref) {
  return FavoritesSyncService(ref);
}

class FavoritesSyncService {
  FavoritesSyncService(this._ref);

  final Ref _ref;
  String _wireBlob = '';
  bool _hasHydrated = false;
  bool _isApplyingRemote = false;
  bool _isPushInFlight = false;
  bool _pendingPush = false;
  Timer? _pushTimer;
  int _pushGeneration = 0;

  bool get _hasUnsyncedLocalChanges {
    return _pendingPush ||
        _isPushInFlight ||
        (_pushTimer?.isActive ?? false);
  }

  Future<void> hydrateFromUserSettings(UserSettingsResponse settings) async {
    if (_hasUnsyncedLocalChanges) {
      return;
    }
    final encoded = settings.syncedPreferences;
    final serverState = FavoritesStateCodec.decodeFavoritesFromWire(encoded);
    final dao = _ref.read(fluxerDatabaseProvider).favoriteChannelsDao;
    final localState = await FavoritesStateCodec.readFromDatabase(dao);
    final hasLocalData =
        localState.channels.isNotEmpty || localState.categories.isNotEmpty;
    final hasServerData =
        serverState.channels.isNotEmpty || serverState.categories.isNotEmpty;

    _wireBlob = encoded;
    _hasHydrated = true;

    if (!hasLocalData && !hasServerData) {
      _flushPendingPush();
      return;
    }

    if (FavoritesStateCodec.statesEqual(localState, serverState)) {
      _flushPendingPush();
      return;
    }

    if (hasLocalData && !hasServerData) {
      schedulePush();
      return;
    }

    final FavoritesLocalState target = hasLocalData && hasServerData
        ? FavoritesStateCodec.mergeForMigration(
            local: localState,
            server: serverState,
          )
        : serverState;

    if (!FavoritesStateCodec.statesEqual(target, localState)) {
      await _applyState(target, fromRemote: true);
    }

    if (hasLocalData &&
        hasServerData &&
        !FavoritesStateCodec.statesEqual(target, serverState)) {
      schedulePush();
    } else {
      _flushPendingPush();
    }
  }

  void schedulePush() {
    _pendingPush = true;
    if (_isApplyingRemote) {
      return;
    }
    _pushTimer?.cancel();
    _pushTimer = Timer(_kFavoritesSyncDebounce, () {
      unawaited(_flushPush());
    });
  }

  Future<void> _flushPush() async {
    if (_isApplyingRemote) {
      _pendingPush = true;
      return;
    }
    if (!_hasHydrated) {
      _deferPush();
      return;
    }
    final generation = ++_pushGeneration;
    _isPushInFlight = true;
    try {
      final dao = _ref.read(fluxerDatabaseProvider).favoriteChannelsDao;
      final localState = await FavoritesStateCodec.readFromDatabase(dao);
      final serverState = FavoritesStateCodec.decodeFavoritesFromWire(
        _wireBlob,
      );
      final pushState = FavoritesStateCodec.mergeForMigration(
        local: localState,
        server: serverState,
      );
      if (FavoritesStateCodec.statesEqual(pushState, serverState)) {
        _pendingPush = false;
        return;
      }
      if (!FavoritesStateCodec.statesEqual(pushState, localState)) {
        await _applyState(pushState, fromRemote: false);
      }
      final encoded = FavoritesStateCodec.encodeFavoritesIntoWire(
        currentWire: _wireBlob.isEmpty ? null : _wireBlob,
        local: pushState,
      );
      if (generation != _pushGeneration) {
        return;
      }
      final client = _ref.read(fluxerClientProvider);
      await client.users.updateCurrentUserSettings(
        body: UserSettingsUpdateRequest(syncedPreferences: encoded),
      );
      _wireBlob = encoded;
      _pendingPush = false;
      talker.debug('[FavoritesSync] Pushed favorites to server');
    } on Object catch (error, stackTrace) {
      talker.error('[FavoritesSync] Push failed', error, stackTrace);
    } finally {
      _isPushInFlight = false;
      _flushPendingPush();
    }
  }

  Future<void> applyAfterLocalMutation() async {
    schedulePush();
  }

  void _flushPendingPush() {
    if (!_pendingPush || _isApplyingRemote || _isPushInFlight) {
      return;
    }
    schedulePush();
  }

  void _deferPush() {
    _pendingPush = true;
    _pushTimer?.cancel();
    _pushTimer = Timer(_kFavoritesSyncDebounce, () {
      unawaited(_flushPush());
    });
  }

  Future<void> _applyState(
    FavoritesLocalState state, {
    required bool fromRemote,
  }) async {
    _isApplyingRemote = fromRemote;
    try {
      final dao = _ref.read(fluxerDatabaseProvider).favoriteChannelsDao;
      await dao.replaceAllFromSync(
        channels: state.channels,
        categories: state.categories,
        collapsedCategoryIds: state.collapsedCategoryIds,
        hideMutedChannels: state.hideMutedChannels,
        muted: state.muted,
      );
    } finally {
      _isApplyingRemote = false;
      _flushPendingPush();
    }
  }
}
