import 'dart:async';

import 'package:dio/dio.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/synced_preferences/favorites_state_codec.dart';
import 'package:fluxer_app/core/synced_preferences/synced_preferences_wire_codec.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorites_sync_service.g.dart';

const Duration _kFavoritesSyncDebounce = Duration(milliseconds: 500);
const Duration _kFavoritesRecentAckWindow = Duration(seconds: 60);
const Duration _kFavoritesRateLimitBaseDelay = Duration(seconds: 5);
const int _kFavoritesRateLimitMaxAttempts = 6;

@Riverpod(keepAlive: true)
FavoritesSyncService favoritesSyncService(Ref ref) {
  return FavoritesSyncService(ref);
}

class FavoritesSyncService {
  FavoritesSyncService(this._ref);

  final Ref _ref;
  String _wireBlob = '';
  bool _hasHydrated = false;
  bool _isDirty = false;
  bool _isApplyingRemote = false;
  bool _isPushInFlight = false;
  bool _pendingPush = false;
  DateTime? _recentlyAckedUntil;
  Timer? _pushTimer;
  Timer? _rateLimitTimer;
  int _pushGeneration = 0;
  int _rateLimitAttempts = 0;

  void reset() {
    _pushTimer?.cancel();
    _rateLimitTimer?.cancel();
    _wireBlob = '';
    _hasHydrated = false;
    _isDirty = false;
    _isApplyingRemote = false;
    _isPushInFlight = false;
    _pendingPush = false;
    _recentlyAckedUntil = null;
    _pushGeneration++;
    _rateLimitAttempts = 0;
  }

  void markSessionChanging() {
    _hasHydrated = false;
  }

  Future<void> hydrateFromUserSettings(UserSettingsResponse settings) async {
    final encoded = settings.syncedPreferences;
    _wireBlob = encoded;

    final decodeResult = FavoritesStateCodec.decodeFavoritesFromWireResult(
      encoded,
    );
    if (decodeResult.status == FavoritesWireDecodeStatus.failure) {
      _hasHydrated = true;
      _flushPendingPush();
      return;
    }

    final dao = _ref.read(fluxerDatabaseProvider).favoriteChannelsDao;
    final localState = await FavoritesStateCodec.readFromDatabase(dao);
    final serverState = decodeResult.state;
    final hasLocalData = _hasFavoritesData(localState);
    final hasServerData = _hasFavoritesData(serverState);
    final wasFirstHydrate = !_hasHydrated;

    if (_isFavoritesProtected() && !wasFirstHydrate) {
      await _applyRemoteAdditionsIfNeeded(
        localState: localState,
        serverState: serverState,
      );
      _hasHydrated = true;
      _flushPendingPush();
      return;
    }

    if (wasFirstHydrate &&
        hasLocalData &&
        hasServerData &&
        !FavoritesStateCodec.statesEqual(localState, serverState)) {
      final target = FavoritesStateCodec.mergeForMigration(
        local: localState,
        server: serverState,
      );
      if (!FavoritesStateCodec.statesEqual(target, localState)) {
        await _applyState(target, fromRemote: true);
      }
      if (!FavoritesStateCodec.statesEqual(target, serverState)) {
        _isDirty = true;
        schedulePush();
      } else {
        _isDirty = false;
      }
      _hasHydrated = true;
      _flushPendingPush();
      return;
    }

    if (!hasLocalData && !hasServerData) {
      _isDirty = false;
      _hasHydrated = true;
      _flushPendingPush();
      return;
    }

    if (FavoritesStateCodec.statesEqual(localState, serverState)) {
      _isDirty = false;
      _hasHydrated = true;
      _flushPendingPush();
      return;
    }

    if (hasLocalData && !hasServerData) {
      if (wasFirstHydrate || encoded.isEmpty) {
        _isDirty = true;
        _hasHydrated = true;
        schedulePush();
      }
      _flushPendingPush();
      return;
    }

    await _applyState(serverState, fromRemote: true);
    _isDirty = false;
    _hasHydrated = true;
    _flushPendingPush();
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
      if (FavoritesStateCodec.statesEqual(localState, serverState)) {
        _isDirty = false;
        _pendingPush = false;
        return;
      }
      if (!FavoritesStateCodec.verifyRoundtripStability(localState)) {
        talker.error('[FavoritesSync] Roundtrip unstable, push skipped');
        return;
      }
      final currentWire = _wireBlob.isEmpty ? null : _wireBlob;
      final encoded = FavoritesStateCodec.encodeFavoritesIntoWire(
        currentWire: currentWire,
        local: localState,
      );
      if (generation != _pushGeneration) {
        return;
      }
      final client = _ref.read(fluxerClientProvider);
      await client.users.updateCurrentUserSettings(
        body: UserSettingsUpdateRequest(syncedPreferences: encoded),
      );
      _wireBlob = encoded;
      _isDirty = false;
      _pendingPush = false;
      _recentlyAckedUntil = DateTime.now().add(_kFavoritesRecentAckWindow);
      _rateLimitAttempts = 0;
      talker.debug(
        '[FavoritesSync] Pushed favorites (${encoded.length} bytes, '
        '${SyncedPreferencesWireCodec.countForeignFields(encoded)} foreign fields)',
      );
    } on SyncedPreferencesWireEncodeException catch (error, stackTrace) {
      talker.error('[FavoritesSync] Wire encode failed', error, stackTrace);
    } on Object catch (error, stackTrace) {
      if (_isRateLimitError(error)) {
        _scheduleRateLimitRetry();
        talker.warning('[FavoritesSync] Push rate-limited, will retry');
        return;
      }
      talker.error('[FavoritesSync] Push failed', error, stackTrace);
    } finally {
      _isPushInFlight = false;
      _flushPendingPush();
    }
  }

  Future<void> applyAfterLocalMutation() async {
    _isDirty = true;
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

  void _scheduleRateLimitRetry() {
    _pendingPush = true;
    _pushTimer?.cancel();
    _rateLimitTimer?.cancel();
    _rateLimitAttempts = (_rateLimitAttempts + 1).clamp(
      1,
      _kFavoritesRateLimitMaxAttempts,
    );
    final delay = Duration(
      milliseconds:
          _kFavoritesRateLimitBaseDelay.inMilliseconds *
          (1 << (_rateLimitAttempts - 1).clamp(0, 4)),
    );
    _rateLimitTimer = Timer(delay, () {
      unawaited(_flushPush());
    });
  }

  Future<void> _applyRemoteAdditionsIfNeeded({
    required FavoritesLocalState localState,
    required FavoritesLocalState serverState,
  }) async {
    if (!_hasRemoteAdditions(localState, serverState)) {
      return;
    }
    final target = FavoritesStateCodec.mergeForMigration(
      local: localState,
      server: serverState,
    );
    if (FavoritesStateCodec.statesEqual(target, localState)) {
      return;
    }
    await _applyState(target, fromRemote: true);
  }

  bool _hasRemoteAdditions(
    FavoritesLocalState local,
    FavoritesLocalState remote,
  ) {
    final localIds = local.channels.map((channel) => channel.channelId).toSet();
    final remoteIds = remote.channels
        .map((channel) => channel.channelId)
        .toSet();
    return remoteIds.difference(localIds).isNotEmpty;
  }

  bool _isFavoritesProtected() {
    if (_isDirty || _isPushInFlight || (_pushTimer?.isActive ?? false)) {
      return true;
    }
    return _isRecentlyAcked();
  }

  bool _isRecentlyAcked() {
    final ackedUntil = _recentlyAckedUntil;
    if (ackedUntil == null) {
      return false;
    }
    if (ackedUntil.isAfter(DateTime.now())) {
      return true;
    }
    _recentlyAckedUntil = null;
    return false;
  }

  bool _hasFavoritesData(FavoritesLocalState state) {
    return state.channels.isNotEmpty || state.categories.isNotEmpty;
  }

  bool _isRateLimitError(Object error) {
    if (error is DioException) {
      return error.response?.statusCode == 429;
    }
    return false;
  }

  Future<void> _applyState(
    FavoritesLocalState state, {
    required bool fromRemote,
  }) async {
    _isApplyingRemote = fromRemote;
    try {
      final dao = _ref.read(fluxerDatabaseProvider).favoriteChannelsDao;
      final normalized = FavoritesStateCodec.normalizeForSync(state);
      await dao.replaceAllFromSync(
        channels: normalized.channels,
        categories: normalized.categories,
        collapsedCategoryIds: normalized.collapsedCategoryIds,
        hideMutedChannels: normalized.hideMutedChannels,
        muted: normalized.muted,
      );
    } finally {
      _isApplyingRemote = false;
      _flushPendingPush();
    }
  }
}
