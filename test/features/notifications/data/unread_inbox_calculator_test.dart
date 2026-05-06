import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/notifications/data/unread_inbox_calculator.dart';
import 'package:fluxer_app/features/notifications/domain/unread_inbox_entry.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

String _snowflakeForUtc(DateTime utc) {
  final int ms = utc.millisecondsSinceEpoch;
  final int internal = (ms - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

UserGuildSettingsResponse _guildSettings({
  Map<String, ChannelOverrides>? channelOverrides,
  UserNotificationSettings messageNotifications =
      UserNotificationSettings.inherit,
}) => UserGuildSettingsResponse(
  guildId: 'guild_test_1',
  messageNotifications: messageNotifications,
  muted: false,
  muteConfig: null,
  mobilePush: true,
  suppressEveryone: false,
  suppressRoles: false,
  hideMutedChannels: false,
  channelOverrides: channelOverrides,
  version: 1,
);

UserGuildSettingsResponse _dmSettings({
  Map<String, ChannelOverrides>? channelOverrides,
}) => UserGuildSettingsResponse(
  guildId: null,
  messageNotifications: UserNotificationSettings.allMessages,
  muted: false,
  muteConfig: null,
  mobilePush: true,
  suppressEveryone: false,
  suppressRoles: false,
  hideMutedChannels: false,
  channelOverrides: channelOverrides,
  version: 1,
);

void main() {
  test(
    'guild channel with last message and no read state row appears as unread',
    () async {
      final FluxerDatabase db = FluxerDatabase.forTesting(
        NativeDatabase.memory(),
      );
      addTearDown(db.close);

      const String guildId = 'guild_test_1';
      const String channelId = 'channel_test_1';
      const String userId = 'user_test_1';

      await db.guildDao.upsertServer(
        ServersCompanion.insert(id: guildId, name: 'Test Guild'),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
          lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5))),
        ),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: userId,
          guildId: guildId,
          joinedAt: Value(DateTime.utc(2020, 1, 15)),
        ),
      );

      final List<UnreadInboxEntry> entries =
          await UnreadInboxCalculator.compute(
            db,
            collapsedByChannelId: <String, bool>{},
            currentUserId: userId,
          );

      expect(entries, hasLength(1));
      expect(entries.single.channelId, channelId);
      expect(entries.single.isDm, isFalse);
    },
  );

  test(
    'guild channel without view permission is excluded from unread inbox',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const guildId = 'guild_test_1';
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
      const userId = 'user_test_1';
      await db.guildDao.upsertServer(
        ServersCompanion.insert(
          id: guildId,
          name: 'Test Guild',
          ownerId: const Value('owner'),
        ),
      );
      await db.roleDao.upsertRoles([
        RolesCompanion.insert(
          id: guildId,
          guildId: guildId,
          name: '@everyone',
          permissions: const Value('0'),
        ),
      ]);
      await db.memberDao.upsertMember(
        MembersCompanion.insert(userId: userId, guildId: guildId),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
          lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5, 6))),
        ),
      );

      final entries = await UnreadInboxCalculator.compute(
        db,
        collapsedByChannelId: <String, bool>{},
        currentUserId: userId,
      );

      expect(entries, isEmpty);
    },
  );

  test('guild channel uses join time when read state is missing', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const guildId = 'guild_test_1';
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
    const userId = 'user_test_1';
    await db.guildDao.upsertServer(
      ServersCompanion.insert(
        id: guildId,
        name: 'Test Guild',
        ownerId: const Value('owner'),
      ),
    );
    await db.roleDao.upsertRoles([
      RolesCompanion.insert(
        id: guildId,
        guildId: guildId,
        name: '@everyone',
        permissions: Value(Permission.viewChannel.value.toString()),
      ),
    ]);
    await db.memberDao.upsertMember(
      MembersCompanion.insert(
        userId: userId,
        guildId: guildId,
        joinedAt: Value(DateTime.utc(2026, 5, 6, 12, 1)),
      ),
    );
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: guildId,
        name: 'general',
        lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5, 6, 12))),
      ),
    );

    final entries = await UnreadInboxCalculator.compute(
      db,
      collapsedByChannelId: <String, bool>{},
      currentUserId: userId,
    );

    expect(entries, isEmpty);
  });

  test('guild channel with mentions-only unread badges is excluded from unread '
      'inbox', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const guildId = 'guild_test_1';
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
    const userId = 'user_test_1';
    await db.guildDao.upsertServer(
      ServersCompanion.insert(id: guildId, name: 'Test Guild'),
    );
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: guildId,
        name: 'general',
        lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5))),
      ),
    );
    await db.memberDao.upsertMember(
      MembersCompanion.insert(
        userId: userId,
        guildId: guildId,
        joinedAt: Value(DateTime.utc(2020, 1, 15)),
      ),
    );
    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion.insert(
        guildId: guildId,
        data: jsonEncode(
          _guildSettings(
            channelOverrides: {
              channelId: const ChannelOverrides(
                collapsed: false,
                messageNotifications: UserNotificationSettings.inherit,
                muted: false,
                muteConfig: null,
                unreadBadges: UserNotificationSettings.onlyMentions,
              ),
            },
          ).toJson(),
        ),
      ),
    );

    final entries = await UnreadInboxCalculator.compute(
      db,
      collapsedByChannelId: <String, bool>{},
      currentUserId: userId,
    );

    expect(entries, isEmpty);
  });

  test(
    'muted guild channel with mentions is excluded from unread inbox',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const guildId = 'guild_test_1';
      const channelId = 'channel_test_1';
      await db.guildDao.upsertServer(
        ServersCompanion.insert(id: guildId, name: 'Test Guild'),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
          lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5, 6))),
        ),
      );
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value(channelId),
          mentionCount: Value(2),
        ),
      );
      await db.userGuildSettingsDao.upsert(
        UserGuildSettingsTableCompanion.insert(
          guildId: guildId,
          data: jsonEncode(
            _guildSettings(
              channelOverrides: {
                channelId: const ChannelOverrides(
                  collapsed: false,
                  messageNotifications: UserNotificationSettings.inherit,
                  muted: true,
                  muteConfig: null,
                ),
              },
            ).toJson(),
          ),
        ),
      );

      final entries = await UnreadInboxCalculator.compute(
        db,
        collapsedByChannelId: <String, bool>{},
      );

      expect(entries, isEmpty);
    },
  );

  test(
    'guild channel stays in unread inbox when notifications are mentions only '
    'and unread badges are unset',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const guildId = 'guild_test_1';
      const channelId = 'channel_test_1';
      const userId = 'user_test_1';
      await db.guildDao.upsertServer(
        ServersCompanion.insert(id: guildId, name: 'Test Guild'),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
          lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5))),
        ),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: userId,
          guildId: guildId,
          joinedAt: Value(DateTime.utc(2020, 1, 15)),
        ),
      );
      await db.userGuildSettingsDao.upsert(
        UserGuildSettingsTableCompanion.insert(
          guildId: guildId,
          data: jsonEncode(
            _guildSettings(
              messageNotifications: UserNotificationSettings.onlyMentions,
            ).toJson(),
          ),
        ),
      );

      final entries = await UnreadInboxCalculator.compute(
        db,
        collapsedByChannelId: <String, bool>{},
        currentUserId: userId,
      );

      expect(entries, hasLength(1));
      expect(entries.single.channelId, channelId);
    },
  );

  test('muted DM is excluded from unread inbox', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: 'dm-1',
        recipientId: 'other',
        unreadCount: const Value(0),
      ),
    ]);
    await db.readStateDao.upsertReadState(
      const ReadStatesCompanion(
        channelId: Value('dm-1'),
        mentionCount: Value(4),
      ),
    );
    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion.insert(
        guildId: '@me',
        data: jsonEncode(
          _dmSettings(
            channelOverrides: {
              'dm-1': const ChannelOverrides(
                collapsed: false,
                messageNotifications: UserNotificationSettings.inherit,
                muted: true,
                muteConfig: null,
              ),
            },
          ).toJson(),
        ),
      ),
    );

    final entries = await UnreadInboxCalculator.compute(
      db,
      collapsedByChannelId: <String, bool>{},
    );

    expect(entries, isEmpty);
  });

  test(
    'DM unread inbox entry is derived from read state mention count',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      await db.dmChannelDao.upsertDmChannels([
        DmChannelsCompanion.insert(
          id: 'dm-1',
          recipientId: 'other',
          unreadCount: const Value(0),
        ),
      ]);
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('dm-1'),
          mentionCount: Value(4),
        ),
      );

      final entries = await UnreadInboxCalculator.compute(
        db,
        collapsedByChannelId: <String, bool>{},
      );

      expect(entries, hasLength(1));
      expect(entries.single.channelId, 'dm-1');
      expect(entries.single.mentionCount, 4);
    },
  );
}
