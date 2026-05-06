import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
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

  test('serverUnread suppresses message-only unread when channel badge setting '
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

ProviderContainer _container(FluxerDatabase db) {
  return ProviderContainer(
    overrides: [fluxerDatabaseProvider.overrideWithValue(db)],
  );
}
