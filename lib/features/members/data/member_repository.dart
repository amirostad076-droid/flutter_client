import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/members/domain/member.dart';

class MemberRepository {
  final FluxerDart _client;
  final db.FluxerDatabase _db;

  const MemberRepository(this._client, this._db);

  Stream<List<Member>> watchMembers(String serverId) {
    return _db.memberDao.watchMembers(serverId).asyncMap((members) async {
      final roles = await _db.roleDao.getRoles(serverId);
      final userIds = members.map((m) => m.userId).toList();
      final userList = await _db.userDao.getUsersByIds(userIds);
      final users = {for (final u in userList) u.id: u};

      return members
          .map((m) => Member.fromRow(m, users[m.userId], roles))
          .toList();
    });
  }

  Future<List<Member>> getMembers(String serverId, {int limit = 100}) async {
    List<dynamic> rawList;
    try {
      final response = await _client.getGuildsApi().listGuildMembers2(
        guildId: serverId,
        limit: limit,
      );
      final data = response.data;
      if (data == null) {
        return [];
      }

      rawList = data
          .map(
            (sdk) => {
              'user': {
                'id': sdk.user.id,
                'username': sdk.user.username,
                'discriminator': sdk.user.discriminator,
                'global_name': sdk.user.globalName,
                'avatar': sdk.user.avatar,
                'avatar_color': sdk.user.avatarColor,
                'bot': sdk.user.bot ?? false,
              },
              'nick': sdk.nick,
              'avatar': sdk.avatar,
              'roles': sdk.roles.toList(),
              'joined_at': sdk.joinedAt,
            },
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 200 && e.response?.data != null) {
        rawList = e.response!.data as List<dynamic>;
      } else {
        throw Exception(e.response?.statusMessage ?? 'Failed to fetch members');
      }
    }

    final memberCompanions = <db.MembersCompanion>[];
    final userCompanions = <db.UsersCompanion>[];

    for (final item in rawList) {
      final map = item as Map<String, dynamic>;
      final user = map['user'] as Map<String, dynamic>;

      userCompanions.add(
        db.UsersCompanion.insert(
          id: user['id'] as String,
          username: user['username'] as String,
          discriminator: Value(user['discriminator'] as String? ?? '0000'),
          globalName: Value(user['global_name'] as String?),
          avatar: Value(user['avatar'] as String?),
          avatarColor: Value(user['avatar_color'] as int?),
          isBot: Value(user['bot'] as bool? ?? false),
        ),
      );

      final roles =
          (map['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ??
          <String>[];

      memberCompanions.add(
        db.MembersCompanion.insert(
          userId: user['id'] as String,
          serverId: serverId,
          nickname: Value(map['nick'] as String?),
          serverAvatar: Value(map['avatar'] as String?),
          roleIdsJson: Value(jsonEncode(roles)),
          joinedAt: Value(
            map['joined_at'] != null
                ? DateTime.parse(map['joined_at'] as String)
                : null,
          ),
        ),
      );
    }

    await _db.userDao.upsertUsers(userCompanions);
    await _db.memberDao.upsertMembers(memberCompanions);

    final rows = await _db.memberDao.getMembers(serverId);
    final dbRoles = await _db.roleDao.getRoles(serverId);
    final userIds = rows.map((m) => m.userId).toList();
    final userList = await _db.userDao.getUsersByIds(userIds);
    final users = {for (final u in userList) u.id: u};

    return rows
        .map((m) => Member.fromRow(m, users[m.userId], dbRoles))
        .toList();
  }

  Future<List<MemberRole>> getRoles(String serverId) async {
    List<dynamic> rawList;
    try {
      final response = await _client.getGuildsApi().listGuildRoles(
        guildId: serverId,
      );
      final data = response.data;
      if (data == null) {
        return [];
      }

      rawList = data
          .map(
            (sdk) => {
              'id': sdk.id,
              'name': sdk.name,
              'color': sdk.color,
              'position': sdk.position,
              'hoist': sdk.hoist,
            },
          )
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 200 && e.response?.data != null) {
        rawList = e.response!.data as List<dynamic>;
      } else {
        throw Exception(e.response?.statusMessage ?? 'Failed to fetch roles');
      }
    }

    final companions = rawList.map((item) {
      final map = item as Map<String, dynamic>;
      return db.RolesCompanion.insert(
        id: map['id'] as String,
        serverId: serverId,
        name: map['name'] as String,
        color: map['color'] != null
            ? Value(map['color'] as int)
            : const Value.absent(),
        position: map['position'] != null
            ? Value(map['position'] as int)
            : const Value.absent(),
        isHoisted: map['hoist'] != null
            ? Value(map['hoist'] as bool)
            : const Value.absent(),
      );
    }).toList();

    await _db.roleDao.upsertRoles(companions);

    final rows = await _db.roleDao.getRoles(serverId);
    return rows.map(MemberRole.fromRow).toList();
  }
}
