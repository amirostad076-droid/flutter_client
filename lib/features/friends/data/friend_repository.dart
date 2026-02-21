import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_dart/fluxer_dart.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/features/friends/domain/friend.dart';
import 'package:fluxeron/shared/utils/sdk_converters.dart';

class FriendRepository {
  final FluxerDart _client;
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
      final response = await _client.getUsersApi().listUserRelationships();
      final data = response.data;
      if (data == null) {
        return [];
      }

      final companions = <db.RelationshipsCompanion>[];
      for (final rel in data) {
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

      return data.map(Friend.fromSdk).toList();
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to fetch relationships',
      );
    }
  }

  static int _typeToInt(RelationshipTypes type) {
    if (type == RelationshipTypes.number1) {
      return 1;
    }
    if (type == RelationshipTypes.number2) {
      return 2;
    }
    if (type == RelationshipTypes.number3) {
      return 3;
    }
    if (type == RelationshipTypes.number4) {
      return 4;
    }
    return 1;
  }
}
