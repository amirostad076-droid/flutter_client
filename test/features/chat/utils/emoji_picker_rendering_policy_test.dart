import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/emoji_picker_rendering_policy.dart';

void main() {
  test('uses tight overscan to limit concurrent emoji decode pressure', () {
    expect(kEmojiPickerOverscanRows, 2);
    expect(emojiPickerCacheExtent(rowHeight: 48), 96);
  });

  test('does not track hover state on mobile', () {
    expect(emojiPickerUsesHoverTracking(isMobile: true), isFalse);
    expect(emojiPickerUsesHoverTracking(isMobile: false), isTrue);
  });

  test('defers premium upsell work until after the first frame', () {
    expect(
      emojiPickerShouldBuildUpsell(
        isPremium: false,
        hasSearchQuery: false,
        isFirstFrameSettled: false,
      ),
      isFalse,
    );
    expect(
      emojiPickerShouldBuildUpsell(
        isPremium: false,
        hasSearchQuery: false,
        isFirstFrameSettled: true,
      ),
      isTrue,
    );
    expect(
      emojiPickerShouldBuildUpsell(
        isPremium: true,
        hasSearchQuery: false,
        isFirstFrameSettled: true,
      ),
      isFalse,
    );
    expect(
      emojiPickerShouldBuildUpsell(
        isPremium: false,
        hasSearchQuery: true,
        isFirstFrameSettled: true,
      ),
      isFalse,
    );
  });
}
