import 'dart:convert';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_app/features/chat/domain/message.dart' as domain;
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

void main() {
  group('reaction remove', () {
    const currentUserId = '100';
    const messageId = '500';
    const channelId = '200';
    const thumbsUp = ReactionEmoji(name: '👍');

    Future<FluxerDatabase> createDatabase({
      required int count,
      required bool hasReacted,
    }) async {
      final database = FluxerDatabase.forTesting(NativeDatabase.memory());
      addTearDown(database.close);
      await database.messageDao.upsertMessage(
        domain.Message(
          id: messageId,
          channelId: channelId,
          authorId: '300',
          authorName: 'author',
          content: 'hello',
          timestamp: DateTime.utc(2026, 1, 2),
          reactions: [
            domain.Reaction(
              emoji: thumbsUp.name,
              count: count,
              hasReacted: hasReacted,
            ),
          ],
        ).toCompanion(),
      );
      return database;
    }

    Future<domain.Reaction?> loadReaction(FluxerDatabase database) async {
      final row = await database.messageDao.getMessage(messageId);
      expect(row, isNotNull);
      final reactions = (jsonDecode(row!.reactionsJson) as List<dynamic>)
          .cast<Map<String, dynamic>>();
      if (reactions.isEmpty) {
        return null;
      }
      return domain.Reaction.fromJson(reactions.single);
    }

    Future<void> dispatchRemove({
      required FluxerDatabase database,
      required String userId,
    }) async {
      final handler = GatewayEventHandler(
        database: database,
        currentUserId: currentUserId,
      );
      await handler.handle(
        MessageReactionRemoveEvent(
          channelId: channelId,
          messageId: messageId,
          userId: userId,
          emoji: thumbsUp,
        ),
      );
    }

    test(
      'skips duplicate decrement when current user already unreacted locally',
      () async {
        final database = await createDatabase(count: 2, hasReacted: false);
        await dispatchRemove(database: database, userId: currentUserId);
        final reaction = await loadReaction(database);
        expect(reaction, isNotNull);
        expect(reaction!.count, 2);
        expect(reaction.hasReacted, isFalse);
      },
    );

    test('decrements when current user still has hasReacted true', () async {
      final database = await createDatabase(count: 2, hasReacted: true);
      await dispatchRemove(database: database, userId: currentUserId);
      final reaction = await loadReaction(database);
      expect(reaction, isNotNull);
      expect(reaction!.count, 1);
      expect(reaction.hasReacted, isFalse);
    });

    test('decrements for other users without touching hasReacted', () async {
      final database = await createDatabase(count: 2, hasReacted: true);
      await dispatchRemove(database: database, userId: '999');
      final reaction = await loadReaction(database);
      expect(reaction, isNotNull);
      expect(reaction!.count, 1);
      expect(reaction.hasReacted, isTrue);
    });
  });

  test('READY persists guild stickers from raw guild payload', () async {
    final database = FluxerDatabase.forTesting(NativeDatabase.memory());
    addTearDown(database.close);

    final handler = GatewayEventHandler(database: database);

    await handler.handle(
      ReadyEvent(
        sessionId: 'session-id',
        user: _user(),
        guilds: const [],
        rawGuilds: [_guildWithSticker()],
        privateChannels: const [],
        relationships: const [],
        readStates: const [],
        presences: const [],
      ),
    );

    final stickers = await database.guildStickerDao.getByGuild('200');

    expect(stickers, hasLength(1));
    expect(stickers.single.id, '300');
    expect(stickers.single.name, 'Blob Wave');
    expect(stickers.single.description, 'Waving blob');
    expect(stickers.single.tagsJson, '["wave","hello"]');
    expect(stickers.single.animated, isFalse);
  });
}

UserPrivateResponse _user() => UserPrivateResponse.fromJson({
  'id': '100',
  'username': 'tester',
  'discriminator': '0001',
  'global_name': null,
  'avatar': null,
  'avatar_color': null,
  'bot': false,
  'system': false,
  'flags': 0,
  'is_staff': false,
  'acls': <String>[],
  'traits': <String>[],
  'email': null,
  'phone': null,
  'bio': null,
  'pronouns': null,
  'accent_color': null,
  'banner': null,
  'banner_color': null,
  'mfa_enabled': false,
  'verified': true,
  'has_verified_phone': false,
  'premium_type': null,
  'premium_since': null,
  'premium_until': null,
  'premium_will_cancel': false,
  'premium_billing_cycle': null,
  'premium_lifetime_sequence': null,
  'premium_badge_hidden': false,
  'premium_badge_masked': false,
  'premium_badge_timestamp_hidden': false,
  'premium_badge_sequence_hidden': false,
  'premium_purchase_disabled': false,
  'premium_enabled_override': false,
  'premium_discriminator': false,
  'premium_perks_disabled': false,
  'password_last_changed_at': null,
  'required_actions': <String>[],
  'nsfw_allowed': true,
  'has_dismissed_premium_onboarding': false,
  'has_ever_purchased': false,
  'has_unread_gift_inventory': false,
  'unread_gift_inventory_count': 0,
  'used_mobile_client': true,
  'pending_bulk_message_deletion': null,
});

Map<String, dynamic> _guildWithSticker() => {
  'id': '200',
  'properties': {
    'id': '200',
    'name': 'Sticker Guild',
    'splash_card_alignment': 0,
    'owner_id': '100',
    'system_channel_flags': 0,
    'afk_timeout': 300,
    'features': <String>[],
    'verification_level': 0,
    'mfa_level': 0,
    'nsfw_level': 0,
    'nsfw': false,
    'content_warning_level': 0,
    'explicit_content_filter': 0,
    'default_message_notifications': 0,
    'disabled_operations': 0,
  },
  'channels': <Map<String, Object?>>[],
  'members': <Map<String, Object?>>[],
  'roles': <Map<String, Object?>>[],
  'presences': <Map<String, Object?>>[],
  'voice_states': <Map<String, Object?>>[],
  'emojis': <Map<String, Object?>>[],
  'stickers': [
    {
      'id': '300',
      'name': 'Blob Wave',
      'description': 'Waving blob',
      'tags': ['wave', 'hello'],
      'animated': false,
      'nsfw': false,
    },
  ],
};
