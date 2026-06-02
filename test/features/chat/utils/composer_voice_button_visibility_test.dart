import 'package:fluxer_app/features/chat/providers/channel/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/chat/utils/composer_voice_button_visibility.dart';
import 'package:test/test.dart';

void main() {
  test('shows voice when empty composer and attachments allowed', () {
    expect(
      shouldShowComposerVoiceButton(
        permissions: ChannelMessagePermissions.all,
        hasSendable: false,
        isEditing: false,
      ),
      isTrue,
    );
  });

  test('hides voice when composer has sendable content', () {
    expect(
      shouldShowComposerVoiceButton(
        permissions: ChannelMessagePermissions.all,
        hasSendable: true,
        isEditing: false,
      ),
      isFalse,
    );
  });

  test('hides voice when editing', () {
    expect(
      shouldShowComposerVoiceButton(
        permissions: ChannelMessagePermissions.all,
        hasSendable: false,
        isEditing: true,
      ),
      isFalse,
    );
  });
}
