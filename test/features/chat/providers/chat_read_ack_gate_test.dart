import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/providers/chat_read_ack_gate.dart';

void main() {
  test('allows ack only when viewport is active and at bottom', () {
    final gate = ChatReadAckGate(minInterval: const Duration(seconds: 5));
    final now = DateTime.utc(2026, 5, 6, 12);

    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: false,
        isNearBottom: true,
        now: now,
      ),
      isFalse,
    );
    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: false,
        now: now,
      ),
      isFalse,
    );
    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now,
      ),
      isTrue,
    );
  });

  test('suppresses manual unread channel until it is cleared', () {
    final gate = ChatReadAckGate(minInterval: const Duration(seconds: 5));
    final now = DateTime.utc(2026, 5, 6, 12);

    gate.markManualUnread('channel-1');

    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now,
      ),
      isFalse,
    );

    gate.clearManualUnread('channel-1');

    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now,
      ),
      isTrue,
    );
  });

  test('reports retry delay while throttled', () {
    final gate = ChatReadAckGate(minInterval: const Duration(seconds: 5));
    final now = DateTime.utc(2026, 5, 6, 12);

    gate
      ..markAttemptStarted('channel-1', now: now)
      ..markAttemptFinished('channel-1');

    expect(
      gate.retryDelay(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now.add(const Duration(seconds: 2)),
      ),
      const Duration(seconds: 3),
    );
    expect(
      gate.retryDelay(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now.add(const Duration(seconds: 5)),
      ),
      Duration.zero,
    );
  });

  test('throttles repeated ack attempts and blocks concurrent attempts', () {
    final gate = ChatReadAckGate(minInterval: const Duration(seconds: 5));
    final now = DateTime.utc(2026, 5, 6, 12);

    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now,
      ),
      isTrue,
    );

    gate.markAttemptStarted('channel-1', now: now);

    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now.add(const Duration(seconds: 1)),
      ),
      isFalse,
    );

    gate.markAttemptFinished('channel-1');

    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now.add(const Duration(seconds: 1)),
      ),
      isFalse,
    );
    expect(
      gate.canAttemptAck(
        channelId: 'channel-1',
        isActive: true,
        isNearBottom: true,
        now: now.add(const Duration(seconds: 6)),
      ),
      isTrue,
    );
  });
}
