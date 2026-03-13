import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:fluxeron/core/database/daos/auth_session_dao.dart';
import 'package:fluxeron/core/database/daos/channel_dao.dart';
import 'package:fluxeron/core/database/daos/dm_channel_dao.dart';
import 'package:fluxeron/core/database/daos/member_dao.dart';
import 'package:fluxeron/core/database/daos/message_dao.dart';
import 'package:fluxeron/core/database/daos/read_state_dao.dart';
import 'package:fluxeron/core/database/daos/relationship_dao.dart';
import 'package:fluxeron/core/database/daos/role_dao.dart';
import 'package:fluxeron/core/database/daos/server_dao.dart';
import 'package:fluxeron/core/database/daos/user_dao.dart';
import 'package:fluxeron/core/database/tables/auth_sessions.dart';
import 'package:fluxeron/core/database/tables/channels.dart';
import 'package:fluxeron/core/database/tables/dm_channels.dart';
import 'package:fluxeron/core/database/tables/members.dart';
import 'package:fluxeron/core/database/tables/messages.dart';
import 'package:fluxeron/core/database/tables/read_states.dart';
import 'package:fluxeron/core/database/tables/relationships.dart';
import 'package:fluxeron/core/database/tables/roles.dart';
import 'package:fluxeron/core/database/tables/servers.dart';
import 'package:fluxeron/core/database/tables/users.dart';

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
  ],
  daos: [
    AuthSessionDao,
    UserDao,
    ServerDao,
    ChannelDao,
    MessageDao,
    RoleDao,
    MemberDao,
    RelationshipDao,
    DmChannelDao,
    ReadStateDao,
  ],
)
class FluxerDatabase extends _$FluxerDatabase {
  FluxerDatabase() : super(_openConnection());

  FluxerDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 2;

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
    },
  );

  /// Clears all tables except auth sessions.
  Future<void> clearUserData() async {
    await transaction(() async {
      await userDao.clearAll();
      await serverDao.clearAll();
      await channelDao.clearAll();
      await messageDao.clearAll();
      await roleDao.clearAll();
      await memberDao.clearAll();
      await relationshipDao.clearAll();
      await dmChannelDao.clearAll();
      await readStateDao.clearAll();
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

QueryExecutor _openConnection() => driftDatabase(name: 'fluxer');
