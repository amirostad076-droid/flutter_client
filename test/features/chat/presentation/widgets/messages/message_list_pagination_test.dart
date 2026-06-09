import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/messages/message_list_pagination.dart';

void main() {
  group('MessageListPaginationGuard', () {
    test('blocks pagination while cooldown is active', () {
      final ScrollController controller = ScrollController();
      final MessageListPaginationGuard guard = MessageListPaginationGuard(
        scrollController: controller,
      );
      addTearDown(guard.dispose);
      addTearDown(controller.dispose);
      guard.beginCooldown();
      expect(
        guard.shouldLoadMore(
          hasMoreMessages: true,
          isLoadingMore: false,
          isLoadingNewer: false,
        ),
        isFalse,
      );
      expect(
        guard.shouldLoadNewer(
          hasMoreNewerMessages: true,
          isLoadingMore: false,
          isLoadingNewer: false,
        ),
        isFalse,
      );
    });

    testWidgets('seedScrollPixels enables scroll intent on next pixel change', (
      WidgetTester tester,
    ) async {
      final ScrollController controller = ScrollController();
      final MessageListPaginationGuard guard = MessageListPaginationGuard(
        scrollController: controller,
      );
      addTearDown(guard.dispose);
      addTearDown(controller.dispose);
      await tester.pumpWidget(
        MaterialApp(
          home: SizedBox(
            height: 200,
            child: ListView.builder(
              controller: controller,
              itemCount: 100,
              itemExtent: 48,
              itemBuilder: (BuildContext context, int index) {
                return Text('item $index');
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final double startPixels = controller.position.pixels;
      guard.seedScrollPixels(startPixels);
      controller.jumpTo(startPixels + 10);
      await tester.pump();
      expect(guard.hasUserScrollIntent(controller.position), isTrue);
    });

    test('resetScrollIntent clears cooldown', () {
      final ScrollController controller = ScrollController();
      final MessageListPaginationGuard guard = MessageListPaginationGuard(
        scrollController: controller,
      );
      addTearDown(guard.dispose);
      addTearDown(controller.dispose);
      guard.beginCooldown();
      expect(guard.isOnCooldown, isTrue);
      guard.resetScrollIntent();
      expect(guard.isOnCooldown, isFalse);
    });

    test('blocks pagination while loading flags are set', () {
      final ScrollController controller = ScrollController();
      final MessageListPaginationGuard guard = MessageListPaginationGuard(
        scrollController: controller,
      );
      addTearDown(guard.dispose);
      addTearDown(controller.dispose);
      expect(
        guard.shouldLoadMore(
          hasMoreMessages: true,
          isLoadingMore: true,
          isLoadingNewer: false,
        ),
        isFalse,
      );
      expect(
        guard.shouldLoadNewer(
          hasMoreNewerMessages: true,
          isLoadingMore: false,
          isLoadingNewer: true,
        ),
        isFalse,
      );
    });
  });
}
