import 'dart:convert';
import 'dart:ui';

import 'package:drift/drift.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:riverpod/riverpod.dart';

int? _opaqueRoleColorValue(int? color) {
  if (color == null || color == 0) {
    return null;
  }

  return color | 0xFF000000;
}

Color? _resolveMemberRoleColor(
  Iterable<int?> roleColors, {
  int? fallbackColor,
}) {
  for (final color in roleColors) {
    final resolvedColor = _opaqueRoleColorValue(color);
    if (resolvedColor != null) {
      return Color(resolvedColor);
    }
  }

  final fallback = _opaqueRoleColorValue(fallbackColor);
  return fallback == null ? null : Color(fallback);
}

/// Returns the [Color] of a guild member's highest-positioned
/// role, or `null` when the member has no colored role.
///
/// Checks the local DB first; if the member is missing,
/// fetches from the REST API and caches the result.
final memberRoleColorProvider = FutureProvider.autoDispose
    .family<Color?, (String, String)>((ref, args) async {
      final (userId, guildId) = args;
      final database = ref.watch(fluxerDatabaseProvider);

      var member = await database.memberDao.getMemberByUserId(userId, guildId);

      if (member == null) {
        try {
          final client = ref.read(fluxerClientProvider);
          final sdk = await client.guilds.getGuildMember(
            guildId: guildId,
            userId: userId,
          );
          await database.memberDao.upsertMember(
            db.MembersCompanion.insert(
              userId: sdk.user.id,
              guildId: guildId,
              nick: Value(sdk.nick),
              serverAvatar: Value(sdk.avatar),
              roleIdsJson: Value(jsonEncode(sdk.roles)),
              joinedAt: Value(sdk.joinedAt),
            ),
          );
          member = await database.memberDao.getMemberByUserId(userId, guildId);
        } on Object {
          return null;
        }
      }

      if (member == null) {
        return null;
      }

      List<String> roleIds;
      try {
        final decoded = jsonDecode(member.roleIdsJson);
        roleIds = decoded is List ? decoded.cast<String>() : <String>[];
      } on Object {
        return null;
      }

      final roles = await database.roleDao.getRoles(guildId);
      final roleMap = {for (final role in roles) role.id: role};

      final memberRoles = [
        for (final roleId in roleIds)
          if (roleMap.containsKey(roleId)) roleMap[roleId]!,
      ]..sort((a, b) => b.position.compareTo(a.position));

      return _resolveMemberRoleColor(
        memberRoles.map((role) => role.color),
        fallbackColor: roleMap[guildId]?.color,
      );
    });
