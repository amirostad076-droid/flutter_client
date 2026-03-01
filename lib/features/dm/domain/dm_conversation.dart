import 'package:fluxeron/core/database/fluxer_database.dart' as db;

class DmConversation {
  final String id;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final String recipientStatus;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const DmConversation({
    required this.id,
    required this.recipientId,
    required this.recipientName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.recipientAvatar,
    this.recipientStatus = 'offline',
    this.unreadCount = 0,
  });

  factory DmConversation.fromRow(db.DmChannel row, db.User? recipient) {
    return DmConversation(
      id: row.id,
      recipientId: row.recipientId,
      recipientName: recipient?.globalName ?? recipient?.username ?? 'Unknown',
      recipientAvatar: recipient?.avatar,
      recipientStatus: recipient?.status ?? 'offline',
      lastMessage: row.lastMessage,
      lastMessageTime: row.lastMessageTime,
      unreadCount: row.unreadCount,
    );
  }
}
