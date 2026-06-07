import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/gateway/gateway_event_handler.dart';
import 'package:fluxer_dart/export.dart';
import 'package:fluxer_dart/gateway.dart';

void main() {
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
