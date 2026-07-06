import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/dm/domain/create_dm_restriction.dart';
import 'package:fluxer_app/features/dm/domain/group_dm_utils.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';
import 'package:test/test.dart';

void main() {
  group('canonicalizeRecipientIds', () {
    test('sorts and deduplicates recipient ids', () {
      expect(
        canonicalizeRecipientIds(<String>['3', '1', '2', '1']),
        '["1","2","3"]',
      );
    });

    test('treats different orderings as equal', () {
      expect(
        canonicalizeRecipientIds(<String>['b', 'a']),
        canonicalizeRecipientIds(<String>['a', 'b']),
      );
    });
  });

  group('isDuplicateGroupDmRow', () {
    test('matches group channels with the same recipients', () {
      final db.DmChannel row = db.DmChannel(
        id: '100',
        recipientId: '2',
        type: 3,
        recipientCount: 3,
        recipientIds: '["1","2"]',
        lastMessage: '',
        lastMessageTime: DateTime.utc(2024),
        unreadCount: 0,
      );
      expect(
        isDuplicateGroupDmRow(
          row: row,
          canonicalKey: canonicalizeRecipientIds(<String>['1', '2']),
        ),
        isTrue,
      );
    });

    test('ignores excluded channel id', () {
      final db.DmChannel row = db.DmChannel(
        id: '100',
        recipientId: '2',
        type: 3,
        recipientCount: 3,
        recipientIds: '["1","2"]',
        lastMessage: '',
        lastMessageTime: DateTime.utc(2024),
        unreadCount: 0,
      );
      expect(
        isDuplicateGroupDmRow(
          row: row,
          canonicalKey: canonicalizeRecipientIds(<String>['1', '2']),
          excludeChannelId: '100',
        ),
        isFalse,
      );
    });
  });

  group('getMaxGroupDmOtherRecipients', () {
    test('subtracts current user from limit', () {
      expect(getMaxGroupDmOtherRecipients(49), 48);
    });

    test('never returns negative values', () {
      expect(getMaxGroupDmOtherRecipients(0), 0);
    });
  });

  group('getCreateDmRestriction', () {
    test('returns unclaimed when email is missing', () {
      const UserSettingsViewState settings = UserSettingsViewState();
      expect(getCreateDmRestriction(settings), CreateDmRestriction.unclaimed);
    });

    test('returns unverified when email exists but not verified', () {
      const UserSettingsViewState settings = UserSettingsViewState(
        email: 'user@example.com',
      );
      expect(getCreateDmRestriction(settings), CreateDmRestriction.unverified);
    });

    test('returns null for verified accounts', () {
      const UserSettingsViewState settings = UserSettingsViewState(
        email: 'user@example.com',
        verified: true,
      );
      expect(getCreateDmRestriction(settings), isNull);
    });
  });
}
