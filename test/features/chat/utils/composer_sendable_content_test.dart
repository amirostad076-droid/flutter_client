import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/composer_sendable_content.dart';

void main() {
  group('composerHasSendableContentFromParts', () {
    test('returns false when channel id is empty', () {
      expect(
        composerHasSendableContentFromParts(
          channelId: '',
          wireText: 'hello',
          hasPendingUploads: false,
        ),
        isFalse,
      );
    });

    test('returns false when wire text is whitespace only', () {
      expect(
        composerHasSendableContentFromParts(
          channelId: 'channel-1',
          wireText: '   ',
          hasPendingUploads: false,
        ),
        isFalse,
      );
    });

    test('returns true when wire text is non-empty', () {
      expect(
        composerHasSendableContentFromParts(
          channelId: 'channel-1',
          wireText: 'hello',
          hasPendingUploads: false,
        ),
        isTrue,
      );
    });

    test('returns true when pending uploads exist without text', () {
      expect(
        composerHasSendableContentFromParts(
          channelId: 'channel-1',
          wireText: '',
          hasPendingUploads: true,
        ),
        isTrue,
      );
    });
  });
}
