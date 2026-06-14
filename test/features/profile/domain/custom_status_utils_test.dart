import 'package:fluxer_app/features/profile/domain/custom_status_utils.dart';
import 'package:fluxer_dart/export.dart';
import 'package:test/test.dart';

void main() {
  group('normalizeCustomStatus', () {
    test('returns null for expired status', () {
      final CustomStatusResponse expired = CustomStatusResponse(
        text: 'Away',
        expiresAt: DateTime.utc(2020),
        emojiAnimated: false,
      );
      expect(normalizeCustomStatus(expired), isNull);
    });

    test('returns active status with text', () {
      final CustomStatusResponse active = CustomStatusResponse(
        text: 'Coffee',
        expiresAt: DateTime.utc(2099),
        emojiAnimated: false,
      );
      expect(normalizeCustomStatus(active)?.text, 'Coffee');
    });
  });

  group('buildCustomStatusPayload', () {
    test('prefers emoji id over emoji name', () {
      final CustomStatusPayload payload = buildCustomStatusPayload(
        text: 'Hi',
        emojiId: '123',
        emojiName: '☕',
        expiresAt: null,
      );
      expect(payload.emojiId, '123');
      expect(payload.emojiName, isNull);
    });
  });
}
