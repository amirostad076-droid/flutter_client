import 'dart:convert';

import 'package:drift/drift.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/shared/utils/guild_user_display.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:riverpod/src/providers/future_provider.dart';

final FutureProviderFamily<GuildUserDisplay?, (String, String?)>
guildUserDisplayProvider = FutureProvider.autoDispose
    .family<GuildUserDisplay?, (String, String?)>((ref, args) async {
      final (String userId, String? guildId) = args;
      final db.FluxerDatabase database = ref.watch(fluxerDatabaseProvider);
      db.User? user = await database.userDao.getUserById(userId);
      db.Member? member;
      if (guildId != null && guildId.isNotEmpty) {
        member = await database.memberDao.getMemberByUserId(userId, guildId);
        if (member == null || user == null) {
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
                memberSince: Value(
                  dateTimeFromUserSnowflakeOrNull(sdk.user.id),
                ),
              ),
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
            user = await database.userDao.getUserById(userId);
            member = await database.memberDao.getMemberByUserId(
              userId,
              guildId,
            );
          } on Object {
            // Use the local user row when the member fetch fails.
          }
        }
      }
      if (user == null) {
        return null;
      }
      return resolveGuildUserDisplayFromRows(
        user: user,
        member: member,
        guildId: guildId,
      );
    });
