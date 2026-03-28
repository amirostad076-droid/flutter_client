import 'package:drift/drift.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/database/tables/members.dart';

part 'member_dao.g.dart';

@DriftAccessor(tables: [Members])
class MemberDao extends DatabaseAccessor<FluxerDatabase> with _$MemberDaoMixin {
  MemberDao(super.attachedDatabase);

  Future<Member?> getMemberByUserId(String userId, String serverId) =>
      (select(members)..where(
            (m) => m.userId.equals(userId) & m.serverId.equals(serverId),
          ))
          .getSingleOrNull();

  Future<List<Member>> getMembers(String serverId) =>
      (select(members)..where((m) => m.serverId.equals(serverId))).get();

  Stream<List<Member>> watchMembers(String serverId) =>
      (select(members)..where((m) => m.serverId.equals(serverId))).watch();

  Future<void> upsertMember(MembersCompanion member) =>
      into(members).insertOnConflictUpdate(member);

  Future<void> upsertMembers(List<MembersCompanion> memberList) async {
    await batch((b) {
      for (final member in memberList) {
        b.insert(members, member, onConflict: DoUpdate((_) => member));
      }
    });
  }

  Future<void> deleteMember(String userId, String serverId) => (delete(
    members,
  )..where((m) => m.userId.equals(userId) & m.serverId.equals(serverId))).go();

  Future<void> deleteMembersForServer(String serverId) =>
      (delete(members)..where((m) => m.serverId.equals(serverId))).go();

  Future<void> clearAll() => delete(members).go();
}
