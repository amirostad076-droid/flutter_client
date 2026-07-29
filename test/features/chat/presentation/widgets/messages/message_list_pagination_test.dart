import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_pagination.dart';

void main() {
  const double viewportHeight = 800;

  bool shouldRequest({
    double? distanceFromEdge,
    bool hasMore = true,
    bool isLoading = false,
    bool isUserDrivenScroll = true,
    bool hasActiveJumpTarget = false,
  }) {
    return shouldRequestEdgeLoad(
      distanceFromEdge:
          distanceFromEdge ?? messageListLoadEnterMargin(viewportHeight) - 1,
      viewportHeight: viewportHeight,
      hasMore: hasMore,
      isLoading: isLoading,
      isUserDrivenScroll: isUserDrivenScroll,
      hasActiveJumpTarget: hasActiveJumpTarget,
    );
  }

  group('shouldRequestEdgeLoad', () {
    test('fires on a user-driven in-margin sample', () {
      expect(shouldRequest(), isTrue);
    });

    test('fires at the margin boundary and refuses beyond it', () {
      final double enterMargin = messageListLoadEnterMargin(viewportHeight);

      expect(shouldRequest(distanceFromEdge: enterMargin), isTrue);
      expect(shouldRequest(distanceFromEdge: enterMargin + 1), isFalse);
    });

    test('is a LEVEL: an unchanged in-margin position keeps firing', () {
      // The dead-cursor and in-flight dedupe belong to the view model
      // (progress ledger, isLoading); geometry must never latch. The previous
      // baseline ratchet deadlocked at the hard newer edge: once a landing
      // snapped the viewport to the wall, no reachable position could beat
      // the recorded baseline by the progress delta again.
      expect(shouldRequest(distanceFromEdge: 0), isTrue);
      expect(shouldRequest(distanceFromEdge: 0), isTrue);
      expect(shouldRequest(distanceFromEdge: 0), isTrue);
    });

    test('skips in-margin samples that are not user-driven', () {
      expect(shouldRequest(isUserDrivenScroll: false), isFalse);
    });

    test('skips while an anchor or jump target is active', () {
      expect(shouldRequest(hasActiveJumpTarget: true), isFalse);
    });

    test('skips while the same edge is already loading', () {
      expect(shouldRequest(isLoading: true), isFalse);
    });

    test('skips when the edge has no more messages', () {
      expect(shouldRequest(hasMore: false), isFalse);
    });

    test('clamps the enter margin at the low and high viewport bounds', () {
      expect(messageListLoadEnterMargin(200), 480);
      expect(messageListLoadEnterMargin(800), 720);
      expect(messageListLoadEnterMargin(2000), 900);
    });
  });
}
