import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/organized_guild_list_provider.dart';
import 'package:fluxer_dart/models/user_settings_response_guild_folders.dart';

Guild _guild(String id, {bool unavailable = false}) {
  return Guild(id: id, name: 'Guild $id', unavailable: unavailable);
}

UserSettingsResponseGuildFolders _folder({
  required List<String> guildIds, int? id,
}) {
  return UserSettingsResponseGuildFolders(id: id, guildIds: guildIds);
}

void main() {
  group('computeOrganizedGuildList', () {
    test('returns all guilds when folders are empty', () {
      final guilds = [_guild('a'), _guild('b')];
      final items = computeOrganizedGuildList(guilds: guilds, folders: []);
      expect(items.length, 2);
      expect(items[0], isA<GuildNavbarGuild>());
      expect((items[0] as GuildNavbarGuild).guild.id, 'a');
      expect((items[1] as GuildNavbarGuild).guild.id, 'b');
    });

    test('prepends unplaced guilds before folder items', () {
      final guilds = [_guild('a'), _guild('b')];
      final folders = [_folder(id: 1, guildIds: ['a'])];
      final items = computeOrganizedGuildList(guilds: guilds, folders: folders);
      expect(items.length, 2);
      expect((items[0] as GuildNavbarGuild).guild.id, 'b');
      expect(items[1], isA<GuildNavbarFolder>());
      final folder = items[1] as GuildNavbarFolder;
      expect(folder.guilds.map((g) => g.id).toList(), ['a']);
    });

    test('does not duplicate guilds listed in folders', () {
      final guilds = [_guild('a'), _guild('b')];
      final folders = [_folder(id: -1, guildIds: ['a', 'b'])];
      final items = computeOrganizedGuildList(guilds: guilds, folders: folders);
      expect(items.length, 2);
      expect(items.every((item) => item is GuildNavbarGuild), isTrue);
    });

    test('excludes unavailable guilds from unplaced prepend', () {
      final guilds = [_guild('a'), _guild('b', unavailable: true)];
      final folders = [_folder(id: 1, guildIds: ['a'])];
      final items = computeOrganizedGuildList(guilds: guilds, folders: folders);
      expect(items.length, 1);
      expect(items[0], isA<GuildNavbarFolder>());
    });

    test('renders uncategorized folder entries as top-level guilds', () {
      final guilds = [_guild('a'), _guild('b')];
      final folders = [_folder(id: -1, guildIds: ['b'])];
      final items = computeOrganizedGuildList(guilds: guilds, folders: folders);
      expect(items.length, 2);
      expect((items[0] as GuildNavbarGuild).guild.id, 'a');
      expect((items[1] as GuildNavbarGuild).guild.id, 'b');
    });
  });
}
