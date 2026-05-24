import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/guilds/providers/guild_availability_provider.dart';

void main() {
  group('GuildAvailability', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('loadFromReady tracks unavailable guilds', () {
      container.read(guildAvailabilityProvider.notifier).loadFromReady([
        {'id': 'g1', 'unavailable': true},
        {'id': 'g2', 'unavailable': false},
      ]);
      expect(container.read(guildAvailabilityProvider), {'g1'});
    });

    test('loadFromReady excludes unavailable_hidden guilds', () {
      container.read(guildAvailabilityProvider.notifier).loadFromReady([
        {'id': 'g1', 'unavailable': true, 'unavailable_hidden': true},
        {'id': 'g2', 'unavailable': true},
      ]);
      expect(container.read(guildAvailabilityProvider), {'g2'});
    });

    test('setGuildAvailable removes guild id', () {
      container.read(guildAvailabilityProvider.notifier).loadFromReady([
        {'id': 'g1', 'unavailable': true},
      ]);
      container.read(guildAvailabilityProvider.notifier).setGuildAvailable('g1');
      expect(container.read(guildAvailabilityProvider), isEmpty);
    });

    test('handleGuildAvailability adds when unavailable', () {
      container
          .read(guildAvailabilityProvider.notifier)
          .handleGuildAvailability('g1', unavailable: true);
      expect(container.read(guildAvailabilityProvider), {'g1'});
    });

    test('handleGuildAvailability removes when available', () {
      container.read(guildAvailabilityProvider.notifier).loadFromReady([
        {'id': 'g1', 'unavailable': true},
      ]);
      container
          .read(guildAvailabilityProvider.notifier)
          .handleGuildAvailability('g1', unavailable: false);
      expect(container.read(guildAvailabilityProvider), isEmpty);
    });

    test('handleGuildAvailability ignores hidden unavailable guilds', () {
      container
          .read(guildAvailabilityProvider.notifier)
          .handleGuildAvailability(
            'g1',
            unavailable: true,
            unavailableHidden: true,
          );
      expect(container.read(guildAvailabilityProvider), isEmpty);
    });

    test('clear resets state', () {
      container.read(guildAvailabilityProvider.notifier).loadFromReady([
        {'id': 'g1', 'unavailable': true},
      ]);
      container.read(guildAvailabilityProvider.notifier).clear();
      expect(container.read(guildAvailabilityProvider), isEmpty);
    });
  });
}
