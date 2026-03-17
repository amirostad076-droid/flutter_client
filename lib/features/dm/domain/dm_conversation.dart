import 'package:fluxeron/core/database/fluxer_database.dart' as db;

class DmConversation {
  final String id;
  final int type;
  final String recipientId;
  final String recipientName;
  final String? recipientAvatar;
  final String recipientStatus;
  final String? name;
  final int recipientCount;
  final String lastMessage;
  final DateTime lastMessageTime;
  final int unreadCount;

  const DmConversation({
    required this.id,
    required this.type,
    required this.recipientId,
    required this.recipientName,
    required this.lastMessage,
    required this.lastMessageTime,
    this.name,
    this.recipientAvatar,
    this.recipientStatus = 'offline',
    this.recipientCount = 2,
    this.unreadCount = 0,
  });

  bool get isGroup => type == 3;

  String get displayName => isGroup ? (name ?? 'Group DM') : recipientName;

  int get memberCount => recipientCount;

  factory DmConversation.fromRow(db.DmChannel row, db.User? recipient) {
    return DmConversation(
      id: row.id,
      type: row.type,
      recipientId: row.recipientId,
      recipientName: recipient?.globalName ?? recipient?.username ?? 'Unknown',
      recipientAvatar: recipient?.avatar,
      recipientStatus: recipient?.status ?? 'offline',
      name: row.name,
      recipientCount: row.recipientCount,
      lastMessage: row.lastMessage,
      lastMessageTime: row.lastMessageTime,
      unreadCount: row.unreadCount,
    );
  }
}
