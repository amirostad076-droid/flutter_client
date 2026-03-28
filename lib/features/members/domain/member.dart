import 'dart:convert';

import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/guilds/domain/guild.dart';

class MemberRole {
  final String id;
  final String name;
  final int color;
  final int position;
  final bool isHoisted;

  const MemberRole({
    required this.id,
    required this.name,
    required this.color,
    this.position = 0,
    this.isHoisted = false,
  });

  factory MemberRole.fromRow(db.Role row) {
    return MemberRole(
      id: row.id,
      name: row.name,
      color: row.color,
      position: row.position,
      isHoisted: row.isHoisted,
    );
  }
}

class RoleGroup {
  final MemberRole? role;
  final String displayName;
  final List<Member> members;

  const RoleGroup({
    required this.displayName,
    required this.members,
    this.role,
  });
}

class Member {
  final String id;
  final String username;
  final String? globalName;
  final String? avatar;
  final int? avatarColor;
  final String? nickname;
  final List<MemberRole> roles;
  final String status;
  final bool isOwner;
  final bool isBot;
  final String? customStatus;

  const Member({
    required this.id,
    required this.username,
    this.globalName,
    this.avatar,
    this.avatarColor,
    this.nickname,
    this.roles = const [],
    this.status = 'offline',
    this.isOwner = false,
    this.isBot = false,
    this.customStatus,
  });

  factory Member.fromRow(db.Member row, db.User? user, List<db.Role> allRoles) {
    final roleIds = _parseRoleIds(row.roleIdsJson);
    final roleMap = {for (final r in allRoles) r.id: r};
    final memberRoles = <MemberRole>[
      for (final id in roleIds)
        if (roleMap.containsKey(id)) MemberRole.fromRow(roleMap[id]!),
    ];

    return Member(
      id: row.userId,
      username: user?.username ?? '',
      globalName: row.nickname ?? user?.globalName,
      avatar: row.serverAvatar ?? user?.avatar,
      avatarColor: user?.avatarColor,
      nickname: row.nickname,
      roles: memberRoles,
      status: user?.status ?? 'offline',
      isBot: user?.isBot ?? false,
      customStatus: user?.customStatus,
    );
  }

  String get displayName => nickname ?? globalName ?? username;

  String? get avatarUrl {
    if (avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn/avatars/$id/$avatar.png';
  }

  /// Color of the highest-positioned role, or null.
  int? get roleColor {
    if (roles.isEmpty) {
      return null;
    }
    final sorted = [...roles]..sort((a, b) => b.position.compareTo(a.position));
    return sorted.first.color;
  }

  static List<String> _parseRoleIds(String json) {
    try {
      final decoded = jsonDecode(json);
      if (decoded is List) {
        return decoded.cast<String>();
      }
    } on Object {
      // Fall through to empty list.
    }
    return [];
  }
}

/// Groups members by their highest hoisted role.
List<RoleGroup> groupMembersIntoRoles(List<Member> members) {
  final grouped = <String, List<Member>>{};
  final roleForGroup = <String, MemberRole>{};

  for (final member in members) {
    final hoisted = member.roles.where((r) => r.isHoisted).toList()
      ..sort((a, b) => b.position.compareTo(a.position));

    final groupKey = hoisted.isNotEmpty ? hoisted.first.name : 'Online';

    if (hoisted.isNotEmpty) {
      roleForGroup[groupKey] = hoisted.first;
    }

    grouped.putIfAbsent(groupKey, () => <Member>[]).add(member);
  }

  final groups = <RoleGroup>[];
  for (final entry in grouped.entries) {
    groups.add(
      RoleGroup(
        role: roleForGroup[entry.key],
        displayName: '${entry.key} \u2014 ${entry.value.length}',
        members: entry.value,
      ),
    );
  }

  return groups;
}
