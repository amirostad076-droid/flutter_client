import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:fluxeron/core/database/daos/auth_session_dao.dart';
import 'package:fluxeron/core/database/daos/emoji_usage_dao.dart';
import 'package:fluxeron/core/database/daos/channel_dao.dart';
import 'package:fluxeron/core/database/daos/dm_channel_dao.dart';
import 'package:fluxeron/core/database/daos/member_dao.dart';
import 'package:fluxeron/core/database/daos/message_dao.dart';
import 'package:fluxeron/core/database/daos/read_state_dao.dart';
import 'package:fluxeron/core/database/daos/relationship_dao.dart';
import 'package:fluxeron/core/database/daos/role_dao.dart';
import 'package:fluxeron/core/database/daos/guild_dao.dart';
import 'package:fluxeron/core/database/daos/user_dao.dart';
import 'package:fluxeron/core/database/daos/user_preferences_dao.dart';
import 'package:fluxeron/core/database/tables/auth_sessions.dart';
import 'package:fluxeron/core/database/tables/emoji_usage.dart';
import 'package:fluxeron/core/database/tables/channels.dart';
import 'package:fluxeron/core/database/tables/dm_channels.dart';
import 'package:fluxeron/core/database/tables/members.dart';
import 'package:fluxeron/core/database/tables/messages.dart';
import 'package:fluxeron/core/database/tables/read_states.dart';
import 'package:fluxeron/core/database/tables/relationships.dart';
import 'package:fluxeron/core/database/tables/roles.dart';
import 'package:fluxeron/core/database/tables/servers.dart';
import 'package:fluxeron/core/database/tables/user_preferences.dart';
import 'package:fluxeron/core/database/tables/users.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

part 'fluxer_database.g.dart';

@DriftDatabase(
  tables: [
    AuthSessions,
    Users,
    Servers,
    Channels,
    Messages,
    Roles,
    Members,
    Relationships,
    DmChannels,
    ReadStates,
    UserPreferencesTable,
    EmojiUsage,
  ],
  daos: [
    AuthSessionDao,
    UserDao,
    GuildDao,
    ChannelDao,
    MessageDao,
    RoleDao,
    MemberDao,
    RelationshipDao,
    DmChannelDao,
    ReadStateDao,
    UserPreferencesDao,
    EmojiUsageDao,
  ],
)
class FluxerDatabase extends _$FluxerDatabase {
  FluxerDatabase() : super(_openConnection());

  FluxerDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 7;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        // v2: Add author metadata columns to messages, add indexes.
        await m.addColumn(messages, messages.authorName);
        await m.addColumn(messages, messages.authorAvatar);
        await m.addColumn(messages, messages.authorAvatarColor);

        await m.createIndex(
          Index(
            'idx_messages_channel',
            'CREATE INDEX idx_messages_channel ON messages (channel_id)',
          ),
        );
        await m.createIndex(
          Index(
            'idx_messages_author',
            'CREATE INDEX idx_messages_author ON messages (author_id)',
          ),
        );
        await m.createIndex(
          Index(
            'idx_channels_server',
            'CREATE INDEX idx_channels_server ON channels (server_id)',
          ),
        );
        await m.createIndex(
          Index(
            'idx_roles_server',
            'CREATE INDEX idx_roles_server ON roles (server_id)',
          ),
        );
        await m.createIndex(
          Index(
            'idx_members_server',
            'CREATE INDEX idx_members_server ON members (server_id)',
          ),
        );
      }
      if (from < 3) {
        await m.createTable(userPreferencesTable);
      }
      if (from < 4) {
        await m.addColumn(messages, messages.type);
      }
      if (from < 5) {
        await m.createTable(emojiUsage);
      }
      if (from < 6) {
        await m.addColumn(dmChannels, dmChannels.type);
        await m.addColumn(dmChannels, dmChannels.name);
        await m.addColumn(dmChannels, dmChannels.recipientCount);
      }
      if (from < 7) {
        await m.addColumn(servers, servers.featuresJson);
      }
    },
  );

  /// Clears all tables except auth sessions.
  Future<void> clearUserData() async {
    await transaction(() async {
      await userDao.clearAll();
      await guildDao.clearAll();
      await channelDao.clearAll();
      await messageDao.clearAll();
      await roleDao.clearAll();
      await memberDao.clearAll();
      await relationshipDao.clearAll();
      await dmChannelDao.clearAll();
      await userPreferencesDao.clearAll();
      await readStateDao.clearAll();
      await emojiUsageDao.clearAll();
    });
  }

  /// Clears everything including auth sessions (full logout).
  Future<void> clearAll() async {
    await transaction(() async {
      await authSessionDao.clearSession();
      await clearUserData();
    });
  }
}

QueryExecutor _openConnection() {
  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    return LazyDatabase(() async {
      final dir = await getApplicationDocumentsDirectory();
      final file = File(p.join(dir.path, 'fluxeron', 'fluxer.db'));
      await file.parent.create(recursive: true);
      return NativeDatabase.createInBackground(file);
    });
  }
  return driftDatabase(name: 'fluxer');
}
