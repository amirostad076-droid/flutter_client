import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/members.dart';

part 'member_dao.g.dart';

@DriftAccessor(tables: [Members])
class MemberDao extends DatabaseAccessor<FluxerDatabase> with _$MemberDaoMixin {
  MemberDao(super.attachedDatabase);

  Future<Member?> getMemberByUserId(String userId, String guildId) =>
      (select(members)
            ..where((m) => m.userId.equals(userId) & m.guildId.equals(guildId)))
          .getSingleOrNull();

  Future<List<Member>> getMembers(String guildId) =>
      (select(members)..where((m) => m.guildId.equals(guildId))).get();

  Stream<List<Member>> watchMembers(String guildId) =>
      (select(members)..where((m) => m.guildId.equals(guildId))).watch();

  Future<void> upsertMember(MembersCompanion member) =>
      into(members).insertOnConflictUpdate(member);

  Future<void> upsertMembers(List<MembersCompanion> memberList) async {
    await batch((b) {
      for (final member in memberList) {
        b.insert(members, member, onConflict: DoUpdate((_) => member));
      }
    });
  }

  Future<void> deleteMember(String userId, String guildId) => (delete(
    members,
  )..where((m) => m.userId.equals(userId) & m.guildId.equals(guildId))).go();

  Future<void> deleteMembersForGuild(String guildId) =>
      (delete(members)..where((m) => m.guildId.equals(guildId))).go();

  Future<void> clearAll() => delete(members).go();
}
