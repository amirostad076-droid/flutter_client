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
  static const int _restBackfillPageSize = 100;
  static const int _restBackfillMaxGuildMembers = 1000;

  final FluxerClient _client;
  final db.FluxerDatabase _db;

  const MemberRepository(this._client, this._db);

  Future<List<Member>> getCachedMembers(String guildId) {
    return watchMembers(guildId).first;
  }

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
    final List<GuildMemberResponse> members = await _fetchGuildMemberPage(
      guildId: guildId,
      limit: limit,
    );
    await _upsertGuildMembersFromSdk(guildId, members);
    return getCachedMembers(guildId);
  }

  /// Fills the local cache from REST when gateway lazy sync left the roster sparse.
  Future<void> backfillMembersIfSparse(String guildId) async {
    final db.Server? server = await _db.guildDao.getServerById(guildId);
    if (server == null) {
      return;
    }
    final int expectedCount = server.memberCount;
    if (expectedCount <= 0 || expectedCount > _restBackfillMaxGuildMembers) {
      return;
    }
    int cachedCount = (await _db.memberDao.getMembers(guildId)).length;
    if (cachedCount >= expectedCount) {
      return;
    }
    String? after;
    while (cachedCount < expectedCount) {
      final List<GuildMemberResponse> page = await _fetchGuildMemberPage(
        guildId: guildId,
        limit: _restBackfillPageSize,
        after: after,
      );
      if (page.isEmpty) {
        return;
      }
      await _upsertGuildMembersFromSdk(guildId, page);
      cachedCount = (await _db.memberDao.getMembers(guildId)).length;
      if (page.length < _restBackfillPageSize) {
        return;
      }
      after = page.last.user.id;
    }
  }

  Future<List<GuildMemberResponse>> _fetchGuildMemberPage({
    required String guildId,
    required int limit,
    String? after,
  }) async {
    try {
      return await _client.guilds.listGuildMembers(
        guildId: guildId,
        limit: limit,
        after: after,
      );
    } on DioException catch (e) {
      if (e.response?.statusCode == 200 && e.response?.data != null) {
        final List<dynamic> rawList = e.response!.data as List<dynamic>;
        return rawList
            .map(
              (dynamic item) => GuildMemberResponse.fromJson(
                item as Map<String, Object?>,
              ),
            )
            .toList();
      }
      throw Exception(e.response?.statusMessage ?? 'Failed to fetch members');
    }
  }

  Future<void> _upsertGuildMembersFromSdk(
    String guildId,
    List<GuildMemberResponse> members,
  ) async {
    if (members.isEmpty) {
      return;
    }
    final List<db.UsersCompanion> userCompanions = <db.UsersCompanion>[];
    final List<db.MembersCompanion> memberCompanions = <db.MembersCompanion>[];
    for (final GuildMemberResponse sdk in members) {
      final String userId = sdk.user.id;
      userCompanions.add(
        db.UsersCompanion.insert(
          id: userId,
          username: sdk.user.username,
          discriminator: Value(sdk.user.discriminator),
          globalName: Value(sdk.user.globalName),
          avatar: Value(sdk.user.avatar),
          avatarColor: Value(sdk.user.avatarColor),
          bot: Value(sdk.user.bot ?? false),
          memberSince: Value(dateTimeFromUserSnowflakeOrNull(userId)),
        ),
      );
      memberCompanions.add(
        db.MembersCompanion.insert(
          userId: userId,
          guildId: guildId,
          nick: Value(sdk.nick),
          serverAvatar: Value(sdk.avatar),
          roleIdsJson: Value(jsonEncode(sdk.roles)),
          joinedAt: Value(sdk.joinedAt),
          communicationDisabledUntil: Value(sdk.communicationDisabledUntil),
        ),
      );
    }
    await _db.userDao.upsertUsers(userCompanions);
    await _db.memberDao.upsertMembers(memberCompanions);
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
