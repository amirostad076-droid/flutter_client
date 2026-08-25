import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_field_adapter.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preference_field.dart';
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/pickers.pb.dart'
    as pickers_pb;
import 'package:fluxer_app/core/synced_preferences/generated/fluxer/user/preferences/v1/preferences.pb.dart'
    as pb;
import 'package:fluxer_app/features/chat/domain/favorite_gif_entry.dart';
import 'package:fluxer_app/features/chat/providers/pickers/favorite_gifs_provider.dart';
import 'package:fluxer_app/features/settings/providers/advanced_preferences_provider.dart';
import 'package:protobuf/protobuf.dart' as $pb;

class FavoriteGifsSyncedLocalState {
  const FavoriteGifsSyncedLocalState({
    required this.entries,
    required this.saveAsSavedMedia,
    this.seenFirstTimePrompt = false,
  });

  final List<FavoriteGifEntry> entries;
  final bool saveAsSavedMedia;
  final bool seenFirstTimePrompt;

  static const empty = FavoriteGifsSyncedLocalState(
    entries: [],
    saveAsSavedMedia: false,
  );
}

class FavoriteGifsSyncedField
    extends SyncedFieldAdapter<FavoriteGifsSyncedLocalState> {
  FavoriteGifsSyncedField(this._ref);

  final Ref _ref;

  @override
  SyncedPreferenceField get field => SyncedPreferenceField.favoriteGifs;

  @override
  FavoriteGifsSyncedLocalState readLocal() {
    final favoriteGifs = _ref.read(favoriteGifsProvider);
    final saveAsSavedMedia = _ref
        .read(advancedPreferencesProvider)
        .saveGifFavoritesAsSavedMedia;
    return FavoriteGifsSyncedLocalState(
      entries: favoriteGifs.entries,
      saveAsSavedMedia: saveAsSavedMedia,
      seenFirstTimePrompt: favoriteGifs.seenFirstTimePrompt,
    );
  }

  @override
  Future<void> applyRemote(FavoriteGifsSyncedLocalState value) async {
    _ref.read(favoriteGifsProvider.notifier).applySynced(
      entries: value.entries,
      seenFirstTimePrompt: value.seenFirstTimePrompt,
    );
    await _ref
        .read(advancedPreferencesProvider.notifier)
        .applySyncedSaveGifFavoritesAsSavedMedia(value: value.saveAsSavedMedia);
  }

  @override
  FavoriteGifsSyncedLocalState? readFromProto(pb.SyncedPreferences message) {
    if (!message.hasFavoriteGifs()) {
      return null;
    }
    return _fromProto(message.favoriteGifs);
  }

  @override
  $pb.GeneratedMessage? readWireSubMessage(pb.SyncedPreferences wire) {
    return wire.hasFavoriteGifs() ? wire.favoriteGifs : null;
  }

  @override
  $pb.GeneratedMessage toProtoMessage(FavoriteGifsSyncedLocalState local) {
    return toProtoForPush(local: local);
  }

  @override
  $pb.GeneratedMessage toProtoMessageForPush(
    FavoriteGifsSyncedLocalState local, {
    $pb.GeneratedMessage? wireSubMessage,
  }) {
    return toProtoForPush(
      local: local,
      wireBase: wireSubMessage as pickers_pb.FavoriteGifSettings?,
    );
  }

  @override
  bool statesEqual(
    FavoriteGifsSyncedLocalState a,
    FavoriteGifsSyncedLocalState b,
  ) {
    if (a.saveAsSavedMedia != b.saveAsSavedMedia ||
        a.seenFirstTimePrompt != b.seenFirstTimePrompt ||
        a.entries.length != b.entries.length) {
      return false;
    }
    for (var i = 0; i < a.entries.length; i++) {
      final left = a.entries[i];
      final right = b.entries[i];
      if (left.url != right.url ||
          left.proxyUrl != right.proxyUrl ||
          left.width != right.width ||
          left.height != right.height ||
          left.contentType != right.contentType ||
          left.placeholder != right.placeholder) {
        return false;
      }
    }
    return true;
  }

  @override
  FavoriteGifsSyncedLocalState mergeForMigration({
    required FavoriteGifsSyncedLocalState local,
    required FavoriteGifsSyncedLocalState remote,
  }) {
    return remote;
  }

  @override
  bool verifyRoundtrip(FavoriteGifsSyncedLocalState candidate) {
    final proto = toProtoForPush(local: candidate);
    final roundtripped = _fromProto(proto);
    return statesEqual(candidate, roundtripped);
  }

  static pickers_pb.FavoriteGifSettings toProtoForPush({
    required FavoriteGifsSyncedLocalState local,
    pickers_pb.FavoriteGifSettings? wireBase,
  }) {
    final proto = wireBase != null
        ? (pickers_pb.FavoriteGifSettings()..mergeFromMessage(wireBase))
        : pickers_pb.FavoriteGifSettings();
    proto.entries
      ..clear()
      ..addAll(
        local.entries.map(
          (entry) => pickers_pb.FavoriteGifEntry(
            url: entry.url,
            proxyUrl: entry.proxyUrl,
            width: entry.width,
            height: entry.height,
            contentType: entry.contentType,
            placeholder: entry.placeholder ?? '',
          ),
        ),
      );
    proto.saveAsSavedMedia = local.saveAsSavedMedia;
    proto.seenFirstTimePrompt = local.seenFirstTimePrompt;
    return proto;
  }

  static FavoriteGifsSyncedLocalState _fromProto(
    pickers_pb.FavoriteGifSettings proto,
  ) {
    return FavoriteGifsSyncedLocalState(
      entries: proto.entries
          .map(
            (entry) => FavoriteGifEntry(
              url: entry.url,
              proxyUrl: entry.proxyUrl,
              width: entry.width,
              height: entry.height,
              contentType: entry.contentType,
              placeholder: entry.placeholder.isEmpty ? null : entry.placeholder,
            ),
          )
          .toList(growable: false),
      saveAsSavedMedia: proto.saveAsSavedMedia,
      seenFirstTimePrompt: proto.seenFirstTimePrompt,
    );
  }
}
