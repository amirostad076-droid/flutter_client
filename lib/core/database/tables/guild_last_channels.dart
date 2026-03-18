import 'package:drift/drift.dart';

class GuildLastChannels extends Table {
  TextColumn get guildId => text()();
  TextColumn get channelId => text()();

  @override
  Set<Column> get primaryKey => {guildId};
}
