import 'package:fluxer_dart/export.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;

enum FriendStatus { accepted, pendingIncoming, pendingOutgoing, blocked }

class Friend {
  final String id;
  final String username;
  final String? globalName;
  final String? avatar;
  final int? avatarColor;
  final String status;
  final String? customStatus;
  final FriendStatus friendStatus;
  final String? nickname;
  final DateTime? since;

  const Friend({
    required this.id,
    required this.username,
    required this.friendStatus,
    this.globalName,
    this.avatar,
    this.avatarColor,
    this.status = 'offline',
    this.customStatus,
    this.nickname,
    this.since,
  });

  factory Friend.fromSdk(RelationshipResponse sdk) {
    return Friend(
      id: sdk.user.id,
      username: sdk.user.username,
      globalName: sdk.user.globalName,
      avatar: sdk.user.avatar,
      avatarColor: sdk.user.avatarColor,
      friendStatus: _mapType(sdk.type),
      nickname: sdk.nickname,
      since: sdk.since,
    );
  }

  factory Friend.fromRow(db.Relationship row, db.User? user) {
    return Friend(
      id: row.userId,
      username: user?.username ?? 'Unknown',
      globalName: user?.globalName,
      avatar: user?.avatar,
      avatarColor: user?.avatarColor,
      status: user?.status ?? 'offline',
      customStatus: user?.customStatus,
      friendStatus: _typeFromInt(row.type),
      nickname: row.nickname,
      since: row.since,
    );
  }

  String get displayName => globalName ?? username;

  static FriendStatus _mapType(RelationshipTypes type) => switch (type) {
    RelationshipTypes.friend => FriendStatus.accepted,
    RelationshipTypes.blocked => FriendStatus.blocked,
    RelationshipTypes.incomingRequest => FriendStatus.pendingIncoming,
    RelationshipTypes.outgoingRequest => FriendStatus.pendingOutgoing,
    RelationshipTypes.$unknown => FriendStatus.accepted,
  };

  static FriendStatus _typeFromInt(int type) {
    switch (type) {
      case 1:
        return FriendStatus.accepted;
      case 2:
        return FriendStatus.blocked;
      case 3:
        return FriendStatus.pendingIncoming;
      case 4:
        return FriendStatus.pendingOutgoing;
      default:
        return FriendStatus.accepted;
    }
  }
}
