import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/members/data/member_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_providers.g.dart';

@Riverpod(keepAlive: true)
MemberRepository memberRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return MemberRepository(client, db);
}

/// Emits the member row count for [guildId] so permission-related providers
/// rebuild after membership is synced to the database.
@riverpod
Stream<int> guildMemberRowCount(Ref ref, String guildId) {
  if (guildId.isEmpty) {
    return Stream<int>.value(0);
  }
  final db = ref.watch(fluxerDatabaseProvider);
  return db.memberDao
      .watchMembers(guildId)
      .map((rows) => rows.length)
      .distinct();
}
