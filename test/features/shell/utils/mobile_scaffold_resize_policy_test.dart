import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/shell/utils/mobile_scaffold_resize_policy.dart';

void main() {
  test('mobile chat keeps full-height body while expression panel is open', () {
    expect(
      mobileChannelScaffoldShouldResizeForKeyboard(
        isChatRoute: true,
        isExpressionPanelOpen: true,
      ),
      isFalse,
    );
  });

  test(
    'mobile chat preserves keyboard inset while expression panel is open',
    () {
      expect(
        mobileChannelScaffoldShouldRemoveKeyboardInset(
          isChatRoute: true,
          isExpressionPanelOpen: true,
        ),
        isFalse,
      );
    },
  );

  test('mobile chat resizes for keyboard while expression panel is closed', () {
    expect(
      mobileChannelScaffoldShouldResizeForKeyboard(
        isChatRoute: true,
        isExpressionPanelOpen: false,
      ),
      isTrue,
    );
  });

  test(
    'non-chat mobile channel screens keep default keyboard resize behavior',
    () {
      expect(
        mobileChannelScaffoldShouldResizeForKeyboard(
          isChatRoute: false,
          isExpressionPanelOpen: true,
        ),
        isTrue,
      );
    },
  );
}
