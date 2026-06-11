import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/favorites/data/favorite_channels_repository.dart';
import 'package:fluxer_app/features/favorites/data/favorites_sync_service.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'favorite_channels_provider.g.dart';

@Riverpod(keepAlive: true)
FavoriteChannelsRepository favoriteChannelsRepository(Ref ref) {
  return FavoriteChannelsRepository(
    ref.watch(fluxerDatabaseProvider),
    ref.watch(favoritesSyncServiceProvider),
  );
}

final StreamProvider<List<db.FavoriteChannel>> favoriteChannelsProvider =
    StreamProvider.autoDispose<List<db.FavoriteChannel>>((ref) {
      return ref.watch(favoriteChannelsRepositoryProvider).watchChannels();
    });

// Riverpod's family provider concrete type is not exported by flutter_riverpod.
// ignore: specify_nonobvious_property_types
final favoriteChannelProvider = StreamProvider.autoDispose
    .family<db.FavoriteChannel?, String>((ref, channelId) {
      return ref
          .watch(favoriteChannelsRepositoryProvider)
          .watchChannel(channelId);
    });

final StreamProvider<List<db.FavoriteCategory>> favoriteCategoriesProvider =
    StreamProvider.autoDispose<List<db.FavoriteCategory>>((ref) {
      return ref.watch(favoriteChannelsRepositoryProvider).watchCategories();
    });

final StreamProvider<db.FavoriteSetting> favoriteSettingsProvider =
    StreamProvider.autoDispose<db.FavoriteSetting>((ref) {
      return ref.watch(favoriteChannelsRepositoryProvider).watchSettings();
    });
