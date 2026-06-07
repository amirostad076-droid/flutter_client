import 'package:fluxer_app/features/chat/domain/message.dart';

/// Splits a chronological message list around a pivot for
/// center anchored dual sliver rendering.
class MessageListPivotSplit {
  const MessageListPivotSplit({
    required this.preCenter,
    required this.postCenter,
  });

  /// Older messages rendered in the pre center sliver (grows upward).
  final List<Message> preCenter;

  /// Newer than pivot messages in the post center sliver (grows downward).
  final List<Message> postCenter;

  int get totalCount => preCenter.length + postCenter.length;

  bool containsMessageId(String messageId) {
    return preCenter.any((Message m) => m.id == messageId) ||
        postCenter.any((Message m) => m.id == messageId);
  }

  /// Whether [messageId] lives in the post-center half.
  bool isPostCenter(String messageId) {
    return postCenter.any((Message m) => m.id == messageId);
  }
}

/// Splits [messages] for center anchored scroll layout.
MessageListPivotSplit splitMessagesForCenterSliver({
  required List<Message> messages,
  required String? pivotMessageId,
}) {
  if (messages.isEmpty) {
    return const MessageListPivotSplit(preCenter: [], postCenter: []);
  }
  if (pivotMessageId == null) {
    return MessageListPivotSplit(preCenter: messages, postCenter: const []);
  }
  final int pivotIndex = messages.indexWhere(
    (Message message) => message.id == pivotMessageId,
  );
  if (pivotIndex == -1) {
    return MessageListPivotSplit(preCenter: messages, postCenter: const []);
  }
  return MessageListPivotSplit(
    preCenter: messages.sublist(0, pivotIndex + 1),
    postCenter: pivotIndex + 1 < messages.length
        ? messages.sublist(pivotIndex + 1)
        : const [],
  );
}

/// Resolves the active pivot id from list mode and explicit state.
///
/// When viewing channel latest, [scrollAnchoredPivotMessageId] keeps
/// incoming messages in the post-center sliver while scrolled up.
String? resolvePivotMessageId({
  required bool hasMoreNewerMessages,
  required String? explicitPivotMessageId,
  required String? scrollAnchoredPivotMessageId,
  required List<Message> messages,
}) {
  if (messages.isEmpty) {
    return null;
  }
  if (explicitPivotMessageId != null &&
      messages.any((Message m) => m.id == explicitPivotMessageId)) {
    return explicitPivotMessageId;
  }
  if (!hasMoreNewerMessages) {
    if (scrollAnchoredPivotMessageId != null &&
        messages.any((Message m) => m.id == scrollAnchoredPivotMessageId)) {
      return scrollAnchoredPivotMessageId;
    }
    return null;
  }
  if (scrollAnchoredPivotMessageId != null &&
      messages.any((Message m) => m.id == scrollAnchoredPivotMessageId)) {
    return scrollAnchoredPivotMessageId;
  }
  if (messages.length == 1) {
    return messages.first.id;
  }
  return messages[messages.length - 2].id;
}
