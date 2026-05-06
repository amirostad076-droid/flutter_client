import 'dart:convert';

import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

String _snowflakeForUtc(DateTime utc) {
  final int internal = (utc.millisecondsSinceEpoch - kSnowflakeEpochMs) << 22;
  return internal.toString();
}

UserPartialResponse _user(String id) => UserPartialResponse(
  id: id,
  username: 'user-$id',
  discriminator: '0001',
  globalName: null,
  avatar: null,
  avatarColor: null,
  flags: 0,
);

UserPrivateResponse _privateUser(String id) => UserPrivateResponse(
  hasVerifiedPhone: false,
  username: 'user-$id',
  discriminator: '0001',
  globalName: null,
  avatar: null,
  avatarColor: null,
  privacyAgreedAt: null,
  termsAgreedAt: null,
  pendingBulkMessageDeletion: null,
  flags: 0,
  unreadGiftInventoryCount: 0,
  isStaff: false,
  acls: const [],
  traits: const [],
  email: null,
  hasUnreadGiftInventory: false,
  hasEverPurchased: false,
  id: id,
  bio: null,
  pronouns: null,
  accentColor: null,
  banner: null,
  hasDismissedPremiumOnboarding: false,
  bannerColor: null,
  mfaEnabled: false,
  nsfwAllowed: true,
  verified: true,
  premiumType: null,
  premiumSince: null,
  premiumUntil: null,
  premiumWillCancel: false,
  premiumBillingCycle: null,
  premiumLifetimeSequence: null,
  premiumGraceEndsAt: null,
  premiumDiscriminator: false,
  requiredActions: const [],
  premiumBadgeMasked: false,
  premiumBadgeTimestampHidden: false,
  premiumBadgeSequenceHidden: false,
  premiumPurchaseDisabled: false,
  premiumEnabledOverride: false,
  passwordLastChangedAt: null,
  premiumBadgeHidden: false,
);

MessageResponseSchema _message({
  required String id,
  required String channelId,
  required String authorId,
  bool mentionEveryone = false,
  List<String>? mentionRoles,
}) => MessageResponseSchema(
  id: id,
  channelId: channelId,
  author: _user(authorId),
  type: MessageResponseSchemaTypeType.valueDefault,
  flags: 0,
  content: 'hello',
  timestamp: dateTimeFromUserSnowflakeOrNull(id)!,
  pinned: false,
  mentionEveryone: mentionEveryone,
  mentionRoles: mentionRoles,
);

void main() {
  test('ready stores private settings under @me', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      ReadyEvent(
        sessionId: 'session-1',
        user: _privateUser('me'),
        guilds: const [],
        rawGuilds: const [],
        privateChannels: const [],
        relationships: const [],
        readStates: const [],
        presences: const [],
        userGuildSettings: const [
          UserGuildSettingsResponse(
            guildId: null,
            messageNotifications: UserNotificationSettings.allMessages,
            muted: false,
            muteConfig: null,
            mobilePush: true,
            suppressEveryone: false,
            suppressRoles: false,
            hideMutedChannels: false,
            channelOverrides: {
              'dm-1': ChannelOverrides(
                collapsed: false,
                messageNotifications: UserNotificationSettings.inherit,
                muted: true,
                muteConfig: null,
              ),
            },
            version: 1,
          ),
        ],
      ),
    );

    final settings = await db.userGuildSettingsDao.getByGuildId('@me');
    expect(settings, isNotNull);
    final decoded = UserGuildSettingsResponse.fromJson(
      jsonDecode(settings!.data) as Map<String, dynamic>,
    );
    expect(decoded.channelOverrides?['dm-1']?.muted, isTrue);
  });

  test('own created messages locally ack the channel', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final messageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
      ),
    );

    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      MessageCreateEvent(
        message: _message(
          id: messageId,
          channelId: 'channel-1',
          authorId: 'me',
        ),
      ),
    );

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastMessageId, messageId);
    expect(readState?.mentionCount, 0);
  });

  test('role mentions increment guild channel mention count', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final messageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
      ),
    );
    await db.memberDao.upsertMember(
      MembersCompanion.insert(
        userId: 'me',
        guildId: 'guild-1',
        roleIdsJson: const Value('["role-1"]'),
      ),
    );

    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      MessageCreateEvent(
        message: _message(
          id: messageId,
          channelId: 'channel-1',
          authorId: 'other',
          mentionRoles: const ['role-1'],
        ),
      ),
    );

    final readState = await db.readStateDao.getReadState('channel-1');
    final message = await db.messageDao.getMessage(messageId);
    final mentionRows = await db.notificationDao.getMentionFeedOrdered();
    expect(readState?.mentionCount, 1);
    expect(message?.isMentioned, isTrue);
    expect(mentionRows.map((row) => row.messageId), [messageId]);
  });

  test('suppressed role mentions do not increment mention count', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final messageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
      ),
    );
    await db.memberDao.upsertMember(
      MembersCompanion.insert(
        userId: 'me',
        guildId: 'guild-1',
        roleIdsJson: const Value('["role-1"]'),
      ),
    );
    await db.userGuildSettingsDao.upsert(
      UserGuildSettingsTableCompanion.insert(
        guildId: 'guild-1',
        data: jsonEncode(
          const UserGuildSettingsResponse(
            guildId: 'guild-1',
            messageNotifications: UserNotificationSettings.inherit,
            muted: false,
            muteConfig: null,
            mobilePush: true,
            suppressEveryone: false,
            suppressRoles: true,
            hideMutedChannels: false,
            channelOverrides: null,
            version: 1,
          ).toJson(),
        ),
      ),
    );

    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      MessageCreateEvent(
        message: _message(
          id: messageId,
          channelId: 'channel-1',
          authorId: 'other',
          mentionRoles: const ['role-1'],
        ),
      ),
    );

    final readState = await db.readStateDao.getReadState('channel-1');
    final message = await db.messageDao.getMessage(messageId);
    final mentionRows = await db.notificationDao.getMentionFeedOrdered();
    expect(readState, null);
    expect(message?.isMentioned, isFalse);
    expect(mentionRows, isEmpty);
  });

  test('channel pins update stores latest channel pin timestamp', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const latestPin = '2026-05-06T12:00:00.000Z';
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
      ),
    );
    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      const ChannelPinsUpdateEvent(
        channelId: 'channel-1',
        lastPinTimestamp: latestPin,
      ),
    );

    final channel = await db.channelDao.getChannelById('channel-1');
    final readState = await db.readStateDao.getReadState('channel-1');
    expect(channel?.lastPinTimestamp, latestPin);
    expect(readState?.lastPinTimestamp, isNot(latestPin));
  });

  test('channel pins ack falls back to latest channel pin timestamp', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const latestPin = '2026-05-06T12:00:00.000Z';
    await db.channelDao.upsertChannel(
      ChannelsCompanion.insert(
        id: 'channel-1',
        guildId: 'guild-1',
        name: 'general',
        lastPinTimestamp: const Value(latestPin),
      ),
    );
    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(const ChannelPinsAckEvent(channelId: 'channel-1'));

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastPinTimestamp, latestPin);
  });

  test('channel pins ack stores acknowledged pin timestamp', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    const latestPin = '2026-05-06T12:00:00.000Z';
    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      const ChannelPinsAckEvent(
        channelId: 'channel-1',
        lastPinTimestamp: latestPin,
      ),
    );

    final readState = await db.readStateDao.getReadState('channel-1');
    expect(readState?.lastPinTimestamp, latestPin);
  });

  test('incoming DM messages increment DM unread count', () async {
    final db = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(db.close);
    final messageId = _snowflakeForUtc(DateTime.utc(2026, 5, 6, 12));
    await db.dmChannelDao.upsertDmChannels([
      DmChannelsCompanion.insert(
        id: 'dm-1',
        recipientId: 'other',
        recipientIds: const Value('["other"]'),
      ),
    ]);

    final handler = GatewayEventHandler(database: db, currentUserId: 'me');

    await handler.handle(
      MessageCreateEvent(
        message: _message(id: messageId, channelId: 'dm-1', authorId: 'other'),
      ),
    );

    final dm = await db.dmChannelDao.getDmChannelById('dm-1');
    final readState = await db.readStateDao.getReadState('dm-1');
    expect(dm?.unreadCount, 1);
    expect(readState?.mentionCount, 1);
  });
}
