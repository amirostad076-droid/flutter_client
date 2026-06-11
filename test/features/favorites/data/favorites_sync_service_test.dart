import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/synced_preferences/favorites_state_codec.dart';
import 'package:fluxer_app/features/favorites/data/favorites_sync_service.dart';
import 'package:fluxer_app/features/favorites/providers/favorite_channels_provider.dart';
import 'package:fluxer_dart/export.dart';

void main() {
  group('FavoritesSyncService', () {
    test('defers push until settings hydration completes', () async {
      final database = db.FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      final container = ProviderContainer(
        overrides: [fluxerDatabaseProvider.overrideWithValue(database)],
      );
      addTearDown(container.dispose);
      final repository = container.read(favoriteChannelsRepositoryProvider);

      expect(await repository.addChannel(channelId: 'channel-1'), isTrue);
      expect(await database.favoriteChannelsDao.getChannel('channel-1'), isNotNull);
    });

    test('merges server favorites into push payload', () {
      const server = FavoritesLocalState(
        channels: [
          db.FavoriteChannel(
            channelId: 'desktop-1',
            guildId: 'guild-1',
            position: 0,
          ),
          db.FavoriteChannel(
            channelId: 'desktop-2',
            guildId: 'guild-1',
            position: 1,
          ),
        ],
        categories: [],
        collapsedCategoryIds: [],
        hideMutedChannels: false,
        muted: false,
      );
      const local = FavoritesLocalState(
        channels: [
          db.FavoriteChannel(
            channelId: 'android-1',
            guildId: '@me',
            position: 0,
          ),
        ],
        categories: [],
        collapsedCategoryIds: [],
        hideMutedChannels: false,
        muted: false,
      );

      final merged = FavoritesStateCodec.mergeForMigration(
        local: local,
        server: server,
      );

      expect(
        merged.channels.map((channel) => channel.channelId),
        ['android-1', 'desktop-1', 'desktop-2'],
      );
    });
  });
}
