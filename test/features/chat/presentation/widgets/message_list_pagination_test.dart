import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_list_pagination.dart';

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
