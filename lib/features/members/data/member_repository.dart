import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';

class MemberRepository {
  static const int _mentionAutocompleteMaxMatches = 100;

  final FluxerClient _client;
  final db.FluxerDatabase _db;

  const MemberRepository(this._client, this._db);

  Stream<List<Member>> watchMembers(String guildId) {
    return _db.memberDao.watchMembers(guildId).asyncMap((members) async {
      final roles = await _db.roleDao.getRoles(guildId);
      final userIds = members.map((m) => m.userId).toList();
      final userList = await _db.userDao.getUsersByIds(userIds);
      final users = {for (final u in userList) u.id: u};

      return members
          .map((m) => Member.fromRow(m, users[m.userId], roles))
          .toList();
    });
  }

  Future<List<Member>> getMembers(String guildId, {int limit = 100}) async {
    List<dynamic> rawList;
    try {
      final members = await _client.guilds.listGuildMembers(
        guildId: guildId,
        limit: limit,
      );

      rawList = members
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
              'roles': sdk.roles,
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

      final userId = user['id'] as String;
      userCompanions.add(
        db.UsersCompanion.insert(
          id: userId,
          username: user['username'] as String,
          discriminator: Value(user['discriminator'] as String? ?? '0000'),
          globalName: Value(user['global_name'] as String?),
          avatar: Value(user['avatar'] as String?),
          avatarColor: Value(user['avatar_color'] as int?),
          bot: Value(user['bot'] as bool? ?? false),
          memberSince: Value(dateTimeFromUserSnowflakeOrNull(userId)),
        ),
      );

      final roles =
          (map['roles'] as List<dynamic>?)?.map((r) => r.toString()).toList() ??
          <String>[];

      memberCompanions.add(
        db.MembersCompanion.insert(
          userId: user['id'] as String,
          guildId: guildId,
          nick: Value(map['nick'] as String?),
          serverAvatar: Value(map['avatar'] as String?),
          roleIdsJson: Value(jsonEncode(roles)),
          joinedAt: Value(map['joined_at'] as DateTime?),
        ),
      );
    }

    await _db.userDao.upsertUsers(userCompanions);
    await _db.memberDao.upsertMembers(memberCompanions);

    final rows = await _db.memberDao.getMembers(guildId);
    final dbRoles = await _db.roleDao.getRoles(guildId);
    final userIds = rows.map((m) => m.userId).toList();
    final userList = await _db.userDao.getUsersByIds(userIds);
    final users = {for (final u in userList) u.id: u};

    return rows
        .map((m) => Member.fromRow(m, users[m.userId], dbRoles))
        .toList();
  }

  Future<List<MemberRole>> getRoles(String guildId) async {
    List<db.RolesCompanion> companions;
    try {
      final List<GuildRoleResponse> roles = await _client.guilds.listGuildRoles(
        guildId: guildId,
      );
      companions = roles
          .map((GuildRoleResponse r) => roleFromSdk(r, guildId))
          .toList();
    } on DioException catch (e) {
      if (e.response?.statusCode == 200 && e.response?.data != null) {
        final List<dynamic> rawList = e.response!.data as List<dynamic>;
        companions = rawList.map((dynamic item) {
          final Map<String, dynamic> map = item as Map<String, dynamic>;
          return db.RolesCompanion.insert(
            id: map['id'] as String,
            guildId: guildId,
            name: map['name'] as String,
            color: map['color'] != null
                ? Value(map['color'] as int)
                : const Value.absent(),
            position: map['position'] != null
                ? Value(map['position'] as int)
                : const Value.absent(),
            hoist: map['hoist'] != null
                ? Value(map['hoist'] as bool)
                : const Value.absent(),
            mentionable: map['mentionable'] != null
                ? Value(map['mentionable'] as bool)
                : const Value.absent(),
            permissions: map['permissions'] != null
                ? Value(map['permissions'] as String)
                : const Value.absent(),
          );
        }).toList();
      } else {
        throw Exception(e.response?.statusMessage ?? 'Failed to fetch roles');
      }
    }

    await _db.roleDao.upsertRoles(companions);

    final rows = await _db.roleDao.getRoles(guildId);
    return rows.map(MemberRole.fromRow).toList();
  }

  /// Resolves mention matches from the local database.
  ///
  /// Callers should first send gateway opcode 8 (`requestGuildMembers`) with the
  /// same [query] so `GUILD_MEMBERS_CHUNK` can populate rows. Do not use
  /// `POST /guilds/:id/members-search`: that route requires moderation permissions.
  Future<List<Member>> searchMembersForAutocomplete({
    required String guildId,
    required String query,
  }) async {
    final String trimmed = query.trim();
    if (trimmed.isEmpty) {
      return const <Member>[];
    }
    final String qLower = trimmed.toLowerCase();
    final List<db.Member> rows = await _db.memberDao.getMembers(guildId);
    final List<db.Role> roles = await _db.roleDao.getRoles(guildId);
    final List<String> userIds = rows.map((db.Member m) => m.userId).toList();
    final List<db.User> userList = await _db.userDao.getUsersByIds(userIds);
    final Map<String, db.User> users = <String, db.User>{
      for (final db.User u in userList) u.id: u,
    };
    final List<Member> hits = <Member>[];
    for (final db.Member row in rows) {
      final Member m = Member.fromRow(row, users[row.userId], roles);
      if (_mentionHaystackContainsQuery(m, qLower)) {
        hits.add(m);
        if (hits.length >= _mentionAutocompleteMaxMatches) {
          break;
        }
      }
    }
    return hits;
  }
}

bool _mentionHaystackContainsQuery(Member member, String queryLower) {
  final String display =
      member.nickname ?? member.globalName ?? member.username;
  final String haystack =
      '$display ${member.username} ${member.globalName ?? ''}'.toLowerCase();
  return haystack.contains(queryLower);
}
