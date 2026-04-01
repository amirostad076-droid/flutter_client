import 'package:dio/dio.dart';
import 'package:drift/drift.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/shared/utils/sdk_converters.dart';
import 'package:fluxer_dart/export.dart';

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

  Future<void> sendFriendRequest(String userId) async {
    try {
      await _client.users.sendFriendRequest(userId: userId);
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to send friend request',
      );
    }
  }

  Future<void> acceptFriendRequest(String userId) async {
    try {
      await _client.users.acceptOrUpdateFriendRequest(
        userId: userId,
        body: const RelationshipTypePutRequest(),
      );
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to accept friend request',
      );
    }
  }

  Future<void> removeRelationship(String userId) async {
    try {
      await _client.users.removeRelationship(userId: userId);
    } on DioException catch (e) {
      throw Exception(
        e.response?.statusMessage ?? 'Failed to remove relationship',
      );
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      await _client.users.acceptOrUpdateFriendRequest(
        userId: userId,
        body: const RelationshipTypePutRequest(type: RelationshipTypes.blocked),
      );
    } on DioException catch (e) {
      throw Exception(e.response?.statusMessage ?? 'Failed to block user');
    }
  }

  static int _typeToInt(RelationshipTypes type) => type.json ?? 1;
}
