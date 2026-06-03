import 'dart:async';

import 'package:drift/drift.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/shared/providers/member_role_color.dart';
import 'package:fluxer_app/shared/utils/guild_user_display.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:riverpod/src/providers/future_provider.dart';

Future<GuildUserDisplay?> _loadGuildUserDisplayFromDatabase({
  required db.FluxerDatabase database,
  required String userId,
  required String? guildId,
}) async {
  final db.User? user = await database.userDao.getUserById(userId);
  if (user == null) {
    return null;
  }
  db.Member? member;
  if (guildId != null && guildId.isNotEmpty) {
    member = await database.memberDao.getMemberByUserId(userId, guildId);
  }
  return resolveGuildUserDisplayFromRows(
    user: user,
    member: member,
    guildId: guildId,
  );
}

Future<void> _fetchAndCacheGuildMember({
  required Ref ref,
  required String userId,
  required String guildId,
}) async {
  final db.FluxerDatabase database = ref.read(fluxerDatabaseProvider);
  try {
    final sdk = await ref
        .read(fluxerClientProvider)
        .guilds
        .getGuildMember(guildId: guildId, userId: userId);
    await database.userDao.upsertUser(
      db.UsersCompanion.insert(
        id: sdk.user.id,
        username: sdk.user.username,
        discriminator: Value(sdk.user.discriminator),
        globalName: Value(sdk.user.globalName),
        avatar: Value(sdk.user.avatar),
        avatarColor: Value(sdk.user.avatarColor),
        bot: Value(sdk.user.bot ?? false),
        system: Value(sdk.user.system ?? false),
        memberSince: Value(dateTimeFromUserSnowflakeOrNull(sdk.user.id)),
      ),
    );
    await database.memberDao.upsertMember(
      memberCompanionFromSdk(sdk, guildId: guildId),
    );
    ref.invalidate(guildUserDisplayProvider((userId, guildId)));
    ref.invalidate(guildUserDisplayFromDbProvider((userId, guildId)));
    ref.invalidate(memberRoleColorProvider((userId, guildId)));
  } on Object {
    // Keep the cached row when the member fetch fails.
  }
}

final FutureProviderFamily<GuildUserDisplay?, (String, String?)>
guildUserDisplayFromDbProvider = FutureProvider.autoDispose
    .family<GuildUserDisplay?, (String, String?)>((ref, args) async {
      final (String userId, String? guildId) = args;
      final db.FluxerDatabase database = ref.watch(fluxerDatabaseProvider);
      return _loadGuildUserDisplayFromDatabase(
        database: database,
        userId: userId,
        guildId: guildId,
      );
    });

final FutureProviderFamily<GuildUserDisplay?, (String, String?)>
guildUserDisplayProvider = FutureProvider.autoDispose
    .family<GuildUserDisplay?, (String, String?)>((ref, args) async {
      final (String userId, String? guildId) = args;
      final db.FluxerDatabase database = ref.watch(fluxerDatabaseProvider);
      final GuildUserDisplay? display = await _loadGuildUserDisplayFromDatabase(
        database: database,
        userId: userId,
        guildId: guildId,
      );
      if (guildId == null || guildId.isEmpty) {
        return display;
      }
      final db.User? user = await database.userDao.getUserById(userId);
      final db.Member? member = await database.memberDao.getMemberByUserId(
        userId,
        guildId,
      );
      if (user == null || member == null) {
        unawaited(
          _fetchAndCacheGuildMember(
            ref: ref,
            userId: userId,
            guildId: guildId,
          ),
        );
      }
      return display;
    });
