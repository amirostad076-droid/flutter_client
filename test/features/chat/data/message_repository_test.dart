import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/message_repository.dart';

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
}
