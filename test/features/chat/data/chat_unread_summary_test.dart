import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/chat/data/chat_unread_summary.dart';

void main() {
  test('finds oldest unread excluding own messages', () {
    final summary = computeChatUnreadSummary(
      messages: const [
        ChatUnreadMessageRef(id: '100', authorId: 'me'),
        ChatUnreadMessageRef(id: '110', authorId: 'other'),
        ChatUnreadMessageRef(id: '120', authorId: 'other'),
      ],
      ackLastMessageId: '105',
      mentionCount: 0,
      currentUserId: 'me',
    );

    expect(summary.oldestUnreadMessageId, '110');
    expect(summary.loadedUnreadCount, 2);
    expect(summary.displayUnreadCount, 2);
    expect(summary.isEstimated, isFalse);
  });

  test('uses an older loaded message as an exact unread boundary', () {
    final summary = computeChatUnreadSummary(
      messages: const [
        ChatUnreadMessageRef(id: '90', authorId: 'other'),
        ChatUnreadMessageRef(id: '110', authorId: 'other'),
        ChatUnreadMessageRef(id: '120', authorId: 'other'),
      ],
      ackLastMessageId: '100',
      mentionCount: 0,
      currentUserId: 'me',
    );

    expect(summary.oldestUnreadMessageId, '110');
    expect(summary.loadedUnreadCount, 2);
    expect(summary.displayUnreadCount, 2);
    expect(summary.isEstimated, isFalse);
  });

  test('marks count estimated when unread boundary is not loaded', () {
    final summary = computeChatUnreadSummary(
      messages: const [
        ChatUnreadMessageRef(id: '200', authorId: 'other'),
        ChatUnreadMessageRef(id: '210', authorId: 'other'),
      ],
      ackLastMessageId: '100',
      mentionCount: 0,
      currentUserId: 'me',
    );

    expect(summary.oldestUnreadMessageId, '200');
    expect(summary.loadedUnreadCount, 2);
    expect(summary.displayUnreadCount, 2);
    expect(summary.isEstimated, isTrue);
  });

  test('uses mention count as display lower bound', () {
    final summary = computeChatUnreadSummary(
      messages: const [ChatUnreadMessageRef(id: '200', authorId: 'other')],
      ackLastMessageId: '100',
      mentionCount: 5,
      currentUserId: 'me',
    );

    expect(summary.loadedUnreadCount, 1);
    expect(summary.displayUnreadCount, 5);
    expect(summary.isEstimated, isTrue);
  });

  test('does not produce unread summary without ack id', () {
    final summary = computeChatUnreadSummary(
      messages: const [ChatUnreadMessageRef(id: '200', authorId: 'other')],
      ackLastMessageId: null,
      mentionCount: 5,
      currentUserId: 'me',
    );

    expect(summary.oldestUnreadMessageId, isNull);
    expect(summary.loadedUnreadCount, 0);
    expect(summary.displayUnreadCount, 0);
    expect(summary.isEstimated, isFalse);
    expect(summary.hasUnread, isFalse);
  });
}
