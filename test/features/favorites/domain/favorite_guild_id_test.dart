import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/favorites/domain/favorite_guild_id.dart';

void main() {
  group('resolveFavoriteGuildId', () {
    test('uses guild id for server channels', () {
      expect(
        resolveFavoriteGuildId(channelGuildId: 'guild-1', isDm: false),
        'guild-1',
      );
    });

    test('uses @me for direct messages', () {
      expect(
        resolveFavoriteGuildId(channelGuildId: null, isDm: true),
        favoriteDmGuildId,
      );
    });

    test('prefers channel guild id when present for dms', () {
      expect(
        resolveFavoriteGuildId(channelGuildId: 'guild-1', isDm: true),
        'guild-1',
      );
    });
  });
}
