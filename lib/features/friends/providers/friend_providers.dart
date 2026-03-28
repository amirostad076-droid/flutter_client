import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/friends/data/friend_repository.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'friend_providers.g.dart';

@Riverpod(keepAlive: true)
FriendRepository friendRepository(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final db = ref.watch(fluxerDatabaseProvider);
  return FriendRepository(client, db);
}

/// Pending incoming friend request count (type 3 = pendingIncoming).
final pendingFriendRequestCountProvider = StreamProvider<int>((ref) {
  final db = ref.watch(fluxerDatabaseProvider);
  return db.relationshipDao.watchRelationships().map(
    (rows) => rows.where((r) => r.type == 3).length,
  );
});
