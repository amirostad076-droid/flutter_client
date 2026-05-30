import 'package:fluxer_app/features/channels/domain/hide_muted_channels_filter.dart';
import 'package:test/test.dart';

void main() {
  group('shouldShowChannelWhenHidingMuted', () {
    test('shows unmuted channel', () {
      expect(
        shouldShowChannelWhenHidingMuted(
          channelId: 'channel-1',
          mutedChannelIds: const {'other-channel'},
        ),
        isTrue,
      );
    });

    test('hides directly muted channel', () {
      expect(
        shouldShowChannelWhenHidingMuted(
          channelId: 'channel-1',
          mutedChannelIds: const {'channel-1'},
        ),
        isFalse,
      );
    });

    test('shows channel when only parent category is muted', () {
      expect(
        shouldShowChannelWhenHidingMuted(
          channelId: 'channel-1',
          mutedChannelIds: const {'category-1'},
        ),
        isTrue,
      );
    });

    test('shows channel when guild mute is not part of muted set', () {
      expect(
        shouldShowChannelWhenHidingMuted(
          channelId: 'channel-1',
          mutedChannelIds: const {},
        ),
        isTrue,
      );
    });

    test('shows selected channel even when directly muted', () {
      expect(
        shouldShowChannelWhenHidingMuted(
          channelId: 'channel-1',
          mutedChannelIds: const {'channel-1'},
          selectedChannelId: 'channel-1',
        ),
        isTrue,
      );
    });

    test('hides non-selected muted channel when another is selected', () {
      expect(
        shouldShowChannelWhenHidingMuted(
          channelId: 'channel-1',
          mutedChannelIds: const {'channel-1'},
          selectedChannelId: 'channel-2',
        ),
        isFalse,
      );
    });
  });
}
