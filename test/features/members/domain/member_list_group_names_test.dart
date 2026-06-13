import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/members/domain/member_list_group_names.dart';
import 'package:fluxer_app/features/members/domain/member_list_layout.dart';
import 'package:fluxer_dart/gateway.dart';

void main() {
  group('resolveMemberListGroupName', () {
    test('returns online and offline labels', () {
      expect(
        resolveMemberListGroupName(
          groupId: 'online',
          rolesById: const <String, db.Role>{},
        ),
        'Online',
      );
      expect(
        resolveMemberListGroupName(
          groupId: 'offline',
          rolesById: const <String, db.Role>{},
        ),
        'Offline',
      );
    });

    test('returns role name when role is cached', () {
      const String roleId = '1473045383154057326';
      final Map<String, db.Role> rolesById = <String, db.Role>{
        roleId: const db.Role(
          id: roleId,
          guildId: 'guild',
          name: 'Moderator',
          color: 0xFF123456,
          position: 1,
          hoist: true,
          mentionable: false,
          permissions: '0',
        ),
      };
      expect(
        resolveMemberListGroupName(groupId: roleId, rolesById: rolesById),
        'Moderator',
      );
    });

    test('returns opaque role color for group headers', () {
      const String roleId = '1473045383154057326';
      final Map<String, db.Role> rolesById = <String, db.Role>{
        roleId: const db.Role(
          id: roleId,
          guildId: 'guild',
          name: 'Moderator',
          color: 0x3498DB,
          position: 1,
          hoist: true,
          mentionable: false,
          permissions: '0',
        ),
      };
      expect(
        resolveMemberListGroupColor(groupId: roleId, rolesById: rolesById),
        0xFF3498DB,
      );
    });
  });

  group('resolveMemberListGroupHeader', () {
    test('resolves header from layout when group metadata is missing', () {
      const List<MemberListGroup> groups = <MemberListGroup>[
        MemberListGroup(id: 'online', count: 1),
      ];
      final List<MemberListGroupLayout> layouts = buildMemberListLayout(
        <MemberListGroup>[
          const MemberListGroup(id: '1473045383154057326', count: 2),
          const MemberListGroup(id: 'online', count: 1),
        ],
      );
      final Map<String, db.Role> rolesById = <String, db.Role>{
        '1473045383154057326': const db.Role(
          id: '1473045383154057326',
          guildId: 'guild',
          name: 'Admin',
          color: 0xFFABCDEF,
          position: 10,
          hoist: true,
          mentionable: true,
          permissions: '0',
        ),
      };
      final MemberListGroupHeaderData? header = resolveMemberListGroupHeader(
        groups: groups,
        layouts: layouts,
        rowIndex: 0,
        rolesById: rolesById,
      );
      expect(header, isNotNull);
      expect(header!.name, 'Admin');
      expect(header.count, 2);
      expect(header.roleColor, 0xFFABCDEF);
    });
  });
}
