import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';

void main() {
  test('buildMessageCreateBody sends favorite meme ids compactly', () {
    final body = buildMessageCreateBody(content: '', favoriteMemeId: 'meme-1');

    expect(body, {
      'favorite_meme_id': 'meme-1',
      'flags': kMessageFlagCompactAttachments,
    });
  });

  test('buildMessageCreateBody keeps normal text message body minimal', () {
    final body = buildMessageCreateBody(content: 'hello');

    expect(body, {'content': 'hello'});
  });

  test('buildMessageCreateBody includes nonce when provided', () {
    final body = buildMessageCreateBody(
      content: 'hello',
      clientNonce: '1501123056699965440',
    );

    expect(body['content'], 'hello');
    expect(body['nonce'], '1501123056699965440');
  });

  test('buildMessageCreateBody includes replied_user when replying', () {
    final bodyEnabled = buildMessageCreateBody(
      content: 'hello',
      replyToId: '123',
    );
    final bodyDisabled = buildMessageCreateBody(
      content: 'hello',
      replyToId: '123',
      replyMention: false,
    );

    expect(bodyEnabled['message_reference'], {'message_id': '123'});
    expect(bodyEnabled['allowed_mentions'], {'replied_user': true});
    expect(bodyDisabled['allowed_mentions'], {'replied_user': false});
  });

  test(
    'buildMessageCreateBody merges favorite meme flag with explicit flags',
    () {
      final body = buildMessageCreateBody(
        content: 'hi',
        favoriteMemeId: 'meme-1',
        messageFlags: messageFlagSuppressNotifications,
      );

      expect(body['favorite_meme_id'], 'meme-1');
      final flags = body['flags'] as int;
      expect(
        flags & kMessageFlagCompactAttachments,
        kMessageFlagCompactAttachments,
      );
      expect(
        flags & messageFlagSuppressNotifications,
        messageFlagSuppressNotifications,
      );
    },
  );

  test('buildMessageCreateBody passes explicit message flags through', () {
    final body = buildMessageCreateBody(
      content: 'hi',
      messageFlags: messageFlagSuppressNotifications,
    );

    expect(body['flags'], messageFlagSuppressNotifications);
    expect(body.containsKey('favorite_meme_id'), isFalse);
  });

  test('buildMessageCreateBody sets tts when requested', () {
    final body = buildMessageCreateBody(content: 'hi', tts: true);

    expect(body['tts'], true);
  });
}
