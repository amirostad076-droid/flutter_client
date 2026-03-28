import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_dart/export.dart';

import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';

class FriendRepository {
  final FluxerClient _client;
  final db.FluxerDatabase _db;

  const FriendRepository(this._client, this._db);

  Stream<List<Friend>> watchRelationships() {
    return _db.relationshipDao.watchRelationships().asyncMap((rows) async {
      final result = <Friend>[];
      for (final row in rows) {
        final user = await _db.userDao.getUserById(row.userId);
        result.add(Friend.fromRow(row, user));
      }
      return result;
    });
  }

  Future<List<Friend>> getRelationships() async {
    try {
      final relationships = await _client.users.listUserRelationships();

      final companions = <db.RelationshipsCompanion>[];
      for (final rel in relationships) {
        await _db.userDao.upsertUser(userFromPartialSdk(rel.user));
        companions.add(
          db.RelationshipsCompanion.insert(
            userId: rel.user.id,
            type: _typeToInt(rel.type),
            nickname: Value(rel.nickname),
            since: Value(rel.since),
          ),
        );
      }

      await _db.relationshipDao.upsertRelationships(companions);

      return relationships.map(Friend.fromSdk).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to fetch relationships',
      );
    }
  }

  static int _typeToInt(RelationshipTypes type) => type.json ?? 1;
}
