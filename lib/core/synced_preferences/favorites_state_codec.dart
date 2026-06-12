import 'dart:convert';

import 'package:fluxer_app/core/database/daos/favorite_channels_dao.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/synced_preferences/generated/favorites.pb.dart'
    as pb;
import 'package:fluxer_app/core/synced_preferences/synced_preferences_wire_codec.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/favorites/domain/favorite_guild_id.dart';

enum FavoritesWireDecodeStatus { empty, success, failure }

class FavoritesWireDecodeResult {
  const FavoritesWireDecodeResult._({
    required this.status,
    required this.state,
  });

  final FavoritesWireDecodeStatus status;
  final FavoritesLocalState state;

  static const empty = FavoritesWireDecodeResult._(
    status: FavoritesWireDecodeStatus.empty,
    state: FavoritesLocalState.empty,
  );
}

class FavoritesLocalState {
  const FavoritesLocalState({
    required this.channels,
    required this.categories,
    required this.collapsedCategoryIds,
    required this.hideMutedChannels,
    required this.muted,
  });

  final List<db.FavoriteChannel> channels;
  final List<db.FavoriteCategory> categories;
  final List<String> collapsedCategoryIds;
  final bool hideMutedChannels;
  final bool muted;

  static const empty = FavoritesLocalState(
    channels: [],
    categories: [],
    collapsedCategoryIds: [],
    hideMutedChannels: false,
    muted: false,
  );
}

class FavoritesStateCodec {
  const FavoritesStateCodec._();

  static FavoritesLocalState decodeFavoritesFromWire(String encoded) {
    return decodeFavoritesFromWireResult(encoded).state;
  }

  static FavoritesWireDecodeResult decodeFavoritesFromWireResult(
    String encoded,
  ) {
    if (encoded.isEmpty) {
      return FavoritesWireDecodeResult.empty;
    }
    try {
      final bytes = base64Decode(encoded);
      final synced = pb.SyncedPreferences.fromBuffer(bytes);
      if (!synced.hasFavorites()) {
        return FavoritesWireDecodeResult.empty;
      }
      return FavoritesWireDecodeResult._(
        status: FavoritesWireDecodeStatus.success,
        state: normalizeForSync(_fromProto(synced.favorites)),
      );
    } on Object catch (error, stackTrace) {
      talker.error(
        '[FavoritesStateCodec] Failed to decode synced preferences',
        error,
        stackTrace,
      );
      return const FavoritesWireDecodeResult._(
        status: FavoritesWireDecodeStatus.failure,
        state: FavoritesLocalState.empty,
      );
    }
  }

  static FavoritesLocalState decodeFavoritesStateBytes(List<int> bytes) {
    if (bytes.isEmpty) {
      return FavoritesLocalState.empty;
    }
    try {
      final state = pb.FavoritesState.fromBuffer(bytes);
      return normalizeForSync(_fromProto(state));
    } on Object {
      return FavoritesLocalState.empty;
    }
  }

  static String encodeFavoritesIntoWire({
    required String? currentWire,
    required FavoritesLocalState local,
  }) {
    return SyncedPreferencesWireCodec.encodeFavoritesIntoWire(
      currentWire: currentWire,
      local: local,
    );
  }

  static pb.FavoritesState toProto(FavoritesLocalState local) {
    return _toProto(normalizeForSync(local));
  }

  static bool verifyRoundtripStability(FavoritesLocalState candidate) {
    final normalized = normalizeForSync(candidate);
    final roundtripped = normalizeForSync(
      _fromProto(_toProto(normalized)),
    );
    return statesEqual(normalized, roundtripped);
  }

  static FavoritesLocalState normalizeForSync(FavoritesLocalState state) {
    return FavoritesLocalState(
      channels: [
        for (final channel in state.channels)
          db.FavoriteChannel(
            channelId: channel.channelId,
            guildId: _normalizeGuildIdForStorage(channel.guildId),
            parentId: _normalizeOptionalString(channel.parentId),
            position: channel.position,
            nickname: _normalizeOptionalString(channel.nickname),
          ),
      ],
      categories: state.categories,
      collapsedCategoryIds: _normalizeCollapsedCategoryIds(
        state.collapsedCategoryIds,
      ),
      hideMutedChannels: state.hideMutedChannels,
      muted: state.muted,
    );
  }

  static bool statesEqual(FavoritesLocalState a, FavoritesLocalState b) {
    final left = normalizeForSync(a);
    final right = normalizeForSync(b);
    if (left.hideMutedChannels != right.hideMutedChannels ||
        left.muted != right.muted) {
      return false;
    }
    if (!_stringSetsEqual(left.collapsedCategoryIds, right.collapsedCategoryIds)) {
      return false;
    }
    if (left.channels.length != right.channels.length ||
        left.categories.length != right.categories.length) {
      return false;
    }
    final sortedChannelsA = [...left.channels]
      ..sort((x, y) => x.position.compareTo(y.position));
    final sortedChannelsB = [...right.channels]
      ..sort((x, y) => x.position.compareTo(y.position));
    for (var i = 0; i < sortedChannelsA.length; i++) {
      final channelA = sortedChannelsA[i];
      final channelB = sortedChannelsB[i];
      if (channelA.channelId != channelB.channelId ||
          _normalizeGuildIdForCompare(channelA.guildId) !=
              _normalizeGuildIdForCompare(channelB.guildId) ||
          channelA.parentId != channelB.parentId ||
          channelA.position != channelB.position ||
          channelA.nickname != channelB.nickname) {
        return false;
      }
    }
    final sortedCategoriesA = [...left.categories]
      ..sort((x, y) => x.position.compareTo(y.position));
    final sortedCategoriesB = [...right.categories]
      ..sort((x, y) => x.position.compareTo(y.position));
    for (var i = 0; i < sortedCategoriesA.length; i++) {
      final categoryA = sortedCategoriesA[i];
      final categoryB = sortedCategoriesB[i];
      if (categoryA.id != categoryB.id ||
          categoryA.name != categoryB.name ||
          categoryA.position != categoryB.position) {
        return false;
      }
    }
    return true;
  }

  static bool _stringSetsEqual(List<String> a, List<String> b) {
    if (a.length != b.length) {
      return false;
    }
    final setA = a.toSet();
    return setA.length == b.length && setA.containsAll(b);
  }

  static FavoritesLocalState mergeForMigration({
    required FavoritesLocalState local,
    required FavoritesLocalState server,
  }) {
    final normalizedLocal = normalizeForSync(local);
    final normalizedServer = normalizeForSync(server);
    final seenChannels = <String>{};
    final channels = <db.FavoriteChannel>[];
    var position = 0;
    for (final channel in [
      ...normalizedLocal.channels,
      ...normalizedServer.channels,
    ]) {
      if (seenChannels.contains(channel.channelId)) {
        continue;
      }
      seenChannels.add(channel.channelId);
      channels.add(
        db.FavoriteChannel(
          channelId: channel.channelId,
          guildId: channel.guildId,
          parentId: channel.parentId,
          position: position++,
          nickname: channel.nickname,
        ),
      );
    }

    final seenCategories = <String>{};
    final categories = <db.FavoriteCategory>[];
    var categoryPosition = 0;
    for (final category in [
      ...normalizedLocal.categories,
      ...normalizedServer.categories,
    ]) {
      if (seenCategories.contains(category.id)) {
        continue;
      }
      seenCategories.add(category.id);
      categories.add(
        db.FavoriteCategory(
          id: category.id,
          name: category.name,
          position: categoryPosition++,
        ),
      );
    }

    final collapsed = {
      ...normalizedLocal.collapsedCategoryIds,
      ...normalizedServer.collapsedCategoryIds,
    }.toList();

    return normalizeForSync(
      FavoritesLocalState(
        channels: channels,
        categories: categories,
        collapsedCategoryIds: collapsed,
        hideMutedChannels: normalizedLocal.hideMutedChannels,
        muted: normalizedLocal.muted,
      ),
    );
  }

  static Future<FavoritesLocalState> readFromDatabase(
    FavoriteChannelsDao dao,
  ) async {
    final channels = await dao.watchChannels().first;
    final categories = await dao.getCategories();
    final settings = await dao.getSettings();
    return normalizeForSync(
      FavoritesLocalState(
        channels: channels,
        categories: categories,
        collapsedCategoryIds: favoriteSettingsCollapsedCategoryIds(settings),
        hideMutedChannels: settings.hideMuted,
        muted: settings.muted,
      ),
    );
  }

  static FavoritesLocalState _fromProto(pb.FavoritesState state) {
    return FavoritesLocalState(
      channels: [
        for (final channel in state.channels)
          db.FavoriteChannel(
            channelId: channel.channelId,
            guildId: channel.guildId.isEmpty ? null : channel.guildId,
            parentId: channel.hasParentId() && channel.parentId.isNotEmpty
                ? channel.parentId
                : null,
            position: channel.position,
            nickname: channel.hasNickname() && channel.nickname.isNotEmpty
                ? channel.nickname
                : null,
          ),
      ],
      categories: [
        for (final category in state.categories)
          db.FavoriteCategory(
            id: category.id,
            name: category.name,
            position: category.position,
          ),
      ],
      collapsedCategoryIds: state.collapsedCategoryIds.toList(),
      hideMutedChannels: state.hideMutedChannels,
      muted: state.muted,
    );
  }

  static pb.FavoritesState _toProto(FavoritesLocalState local) {
    return pb.FavoritesState(
      channels: [
        for (final channel in local.channels)
          pb.FavoriteChannel(
            channelId: channel.channelId,
            guildId: _encodeGuildIdForWire(channel.guildId),
            parentId: channel.parentId ?? '',
            position: channel.position,
            nickname: channel.nickname ?? '',
          ),
      ],
      categories: [
        for (final category in local.categories)
          pb.FavoriteCategory(
            id: category.id,
            name: category.name,
            position: category.position,
          ),
      ],
      collapsedCategoryIds: local.collapsedCategoryIds,
      hideMutedChannels: local.hideMutedChannels,
      muted: local.muted,
    );
  }

  static String? _normalizeGuildIdForStorage(String? guildId) {
    final trimmed = guildId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static String _normalizeGuildIdForCompare(String? guildId) {
    final trimmed = guildId?.trim();
    if (trimmed == null ||
        trimmed.isEmpty ||
        trimmed == favoriteDmGuildId) {
      return favoriteDmGuildId;
    }
    return trimmed;
  }

  static String _encodeGuildIdForWire(String? guildId) {
    final trimmed = guildId?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return favoriteDmGuildId;
    }
    return trimmed;
  }

  static String? _normalizeOptionalString(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }
    return trimmed;
  }

  static List<String> _normalizeCollapsedCategoryIds(List<String> values) {
    final seen = <String>{};
    final normalized = <String>[];
    for (final value in values) {
      final trimmed = value.trim();
      if (trimmed.isEmpty || seen.contains(trimmed)) {
        continue;
      }
      seen.add(trimmed);
      normalized.add(trimmed);
    }
    return normalized;
  }
}
