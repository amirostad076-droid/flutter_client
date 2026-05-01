import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/utils/emoji_picker_rendering_policy.dart';

void main() {
  test('uses web-matched five row overscan for emoji picker rendering', () {
    expect(kEmojiPickerOverscanRows, 5);
    expect(emojiPickerCacheExtent(rowHeight: 48), 240);
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
