import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/providers/unread_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

void main() {
  test(
    'channelUnread uses channel last message when no messages are cached',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);

      final subscription = container.listen(
        channelUnreadProvider(channelId),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        channelUnreadProvider(channelId).future,
      );

      expect(unread.hasUnread, isTrue);
      expect(unread.mentionCount, 0);
    },
  );

  test(
    'channelUnread reports unread pins when channel pins are newer',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      const latestPin = '2026-05-06T12:00:00.000Z';
      const ackedPin = '2026-05-05T12:00:00.000Z';
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: 'channel-1',
          guildId: 'guild-1',
          name: 'general',
          lastPinTimestamp: const Value(latestPin),
        ),
      );
      await db.readStateDao.upsertReadState(
        const ReadStatesCompanion(
          channelId: Value('channel-1'),
          lastPinTimestamp: Value(ackedPin),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);
      final subscription = container.listen(
        channelUnreadProvider('channel-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        channelUnreadProvider('channel-1').future,
      );

      expect(unread.hasUnreadPins, isTrue);
    },
  );

  test('serverUnread hides plain unread when channel badge setting '
      'is mentions only', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
    final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(lastMessageId),
      ),
    );
    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion.insert(
        guildId: 'guild-1',
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

    final container = _container(db);
    addTearDown(container.dispose);
    final subscription = container.listen(
      serverUnreadProvider('guild-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final unread = await container.read(serverUnreadProvider('guild-1').future);

    expect(unread.hasUnread, isFalse);
    expect(unread.mentionCount, 0);
  });

  test(
    'serverUnread hides mentions when channel badge setting is no messages',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );
      await db.readStateDao.upsertReadState(
        ReadStatesCompanion(
          channelId: Value(channelId),
          lastMessageId: Value(_snowflakeForUtc(DateTime.utc(2026, 5, 5))),
          mentionCount: const Value(2),
        ),
      );
      await db.userGuildSettingsDao.upsert(
        UserGuildSettingsTableCompanion.insert(
          guildId: 'guild-1',
          data: jsonEncode(
            _guildSettings(
              channelOverrides: {
                channelId: const ChannelOverrides(
                  collapsed: false,
                  messageNotifications: UserNotificationSettings.inherit,
                  muted: false,
                  muteConfig: null,
                  unreadBadges: UserNotificationSettings.noMessages,
                ),
              },
            ).toJson(),
          ),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);
      final subscription = container.listen(
        serverUnreadProvider('guild-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        serverUnreadProvider('guild-1').future,
      );

      expect(unread.hasUnread, isFalse);
      expect(unread.mentionCount, 0);
    },
  );

  test(
    'serverUnread honors expired category mute for child channels',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final categoryId = _snowflakeForUtc(DateTime.utc(2026, 5));
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5, 1, 1));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
      await db.channelDao.upsertChannels([
        ChannelsCompanion.insert(
          id: categoryId,
          guildId: 'guild-1',
          name: 'Category',
          type: const Value(4),
        ),
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          parentId: Value(categoryId),
          lastMessageId: Value(lastMessageId),
        ),
      ]);
      await db.userGuildSettingsDao.upsert(
        UserGuildSettingsTableCompanion.insert(
          guildId: 'guild-1',
          data: jsonEncode(
            _guildSettings(
              channelOverrides: {
                categoryId: const ChannelOverrides(
                  collapsed: false,
                  messageNotifications: UserNotificationSettings.inherit,
                  muted: true,
                  muteConfig: ChannelOverridesMuteConfig(
                    endTime: '2026-05-05T00:00:00.000Z',
                    selectedTimeWindow: 3600,
                  ),
                ),
              },
            ).toJson(),
          ),
        ),
      );

      final container = _container(db);
      addTearDown(container.dispose);
      final subscription = container.listen(
        serverUnreadProvider('guild-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        serverUnreadProvider('guild-1').future,
      );

      expect(unread.hasUnread, isTrue);
    },
  );

  test('serverUnread keeps message unread when notifications are mentions only '
      'and unread badges are unset', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
    final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(lastMessageId),
      ),
    );
    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion.insert(
        guildId: 'guild-1',
        data: jsonEncode(
          _guildSettings(
            messageNotifications: UserNotificationSettings.onlyMentions,
          ).toJson(),
        ),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    final subscription = container.listen(
      serverUnreadProvider('guild-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final unread = await container.read(serverUnreadProvider('guild-1').future);

    expect(unread.hasUnread, isTrue);
    expect(unread.mentionCount, 0);
  });

  test('serverUnread excludes channels without view permission', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
    final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
    await db.guildDao.upsertServer(
      ServersCompanion.insert(
        id: 'guild-1',
        name: 'Guild',
        ownerId: const Value('owner'),
      ),
    );
    await db.roleDao.upsertRoles([
      RolesCompanion.insert(
        id: 'guild-1',
        guildId: 'guild-1',
        name: '@everyone',
        permissions: const Value('0'),
      ),
    ]);
    await db.memberDao.upsertMember(
      MembersCompanion.insert(userId: 'me', guildId: 'guild-1'),
    );
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(lastMessageId),
      ),
    );

    final container = _container(db, currentUserId: 'me');
    addTearDown(container.dispose);
    final subscription = container.listen(
      serverUnreadProvider('guild-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final unread = await container.read(serverUnreadProvider('guild-1').future);

    expect(unread.hasUnread, isFalse);
    expect(unread.mentionCount, 0);
  });

  test(
    'serverUnread uses everyone permissions when member row is missing',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
      await db.guildDao.upsertServer(
        ServersCompanion.insert(
          id: 'guild-1',
          name: 'Guild',
          ownerId: const Value('owner'),
        ),
      );
      await db.roleDao.upsertRoles([
        RolesCompanion.insert(
          id: 'guild-1',
          guildId: 'guild-1',
          name: '@everyone',
          permissions: Value(Permission.viewChannel.value.toString()),
        ),
      ]);
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );

      final container = _container(db, currentUserId: 'me');
      addTearDown(container.dispose);
      final subscription = container.listen(
        serverUnreadProvider('guild-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        serverUnreadProvider('guild-1').future,
      );

      expect(unread.hasUnread, isTrue);
      expect(unread.mentionCount, 0);
    },
  );

  test(
    'serverUnread uses member join time when read state is missing',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 11));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
      await db.guildDao.upsertServer(
        ServersCompanion.insert(
          id: 'guild-1',
          name: 'Guild',
          ownerId: const Value('owner'),
        ),
      );
      await db.roleDao.upsertRoles([
        RolesCompanion.insert(
          id: 'guild-1',
          guildId: 'guild-1',
          name: '@everyone',
          permissions: Value(Permission.viewChannel.value.toString()),
        ),
      ]);
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: 'me',
          guildId: 'guild-1',
          joinedAt: Value(DateTime.utc(2026, 5, 6, 12, 1)),
        ),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );

      final container = _container(db, currentUserId: 'me');
      addTearDown(container.dispose);
      final subscription = container.listen(
        serverUnreadProvider('guild-1'),
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final unread = await container.read(
        serverUnreadProvider('guild-1').future,
      );

      expect(unread.hasUnread, isFalse);
      expect(unread.mentionCount, 0);
    },
  );

  test('serverUnread includes channels without read state rows', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final channelId = _snowflakeForUtc(DateTime.utc(2026, 5));
    final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: channelId,
        guildId: 'guild-1',
        name: 'general',
        lastMessageId: Value(lastMessageId),
      ),
    );

    final container = _container(db);
    addTearDown(container.dispose);
    final subscription = container.listen(
      serverUnreadProvider('guild-1'),
      (_, _) {},
      fireImmediately: true,
    );
    addTearDown(subscription.close);

    final unread = await container.read(serverUnreadProvider('guild-1').future);

    expect(unread.hasUnread, isTrue);
    expect(unread.mentionCount, 0);
  });

  test(
    'serverUnread recomputes when READY completes after channel hydration',
    () async {
      final db = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(db.close);
      final channelId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 10));
      final lastMessageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));

      final container = _container(db, currentUserId: 'me');
      addTearDown(container.dispose);
      final provider = serverUnreadProvider('guild-1');
      final subscription = container.listen(
        provider,
        (_, _) {},
        fireImmediately: true,
      );
      addTearDown(subscription.close);

      final initialUnread = await container.read(provider.future);
      expect(initialUnread.hasUnread, isFalse);

      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: 'guild-1',
          name: 'general',
          lastMessageId: Value(lastMessageId),
        ),
      );
      await pumpEventQueue();
      expect(container.read(provider).value?.hasUnread, isFalse);

      await db.guildDao.upsertServer(
        ServersCompanion.insert(
          id: 'guild-1',
          name: 'Guild',
          ownerId: const Value('owner'),
        ),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(
          userId: 'me',
          guildId: 'guild-1',
          joinedAt: Value(DateTime.utc(2026, 5, 6, 11)),
        ),
      );
      container.read(gatewayReadyProvider.notifier).setReady();
      await pumpEventQueue();

      expect(container.read(provider).value?.hasUnread, isTrue);
    },
  );
}

UserGuildSettingsResponse _guildSettings({
  Map<String, ChannelOverrides>? channelOverrides,
  UserNotificationSettings messageNotifications =
      UserNotificationSettings.inherit,
  UserNotificationSettings? unreadBadges,
  bool muted = false,
}) => UserGuildSettingsResponse(
  guildId: 'guild-1',
  messageNotifications: messageNotifications,
  muted: muted,
  muteConfig: null,
  mobilePush: true,
  suppressEveryone: false,
  suppressRoles: false,
  hideMutedChannels: false,
  channelOverrides: channelOverrides,
  unreadBadges: unreadBadges,
  version: 1,
);

ProviderContainer _container(FluxerDatabase db, {String? currentUserId}) {
  return ProviderContainer(
    overrides: [
      fluxerDatabaseProvider.overrideWithValue(db),
      if (currentUserId != null)
        currentUserIdProvider.overrideWithValue(currentUserId),
    ],
  );
}
