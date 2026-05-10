import 'dart:async';

import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_relationship_provider.g.dart';

@riverpod
Stream<Friend?> userRelationship(Ref ref, {required String userId}) {
  final repo = ref.watch(friendRepositoryProvider);
  unawaited(repo.getRelationships().catchError((Object _) => <Friend>[]));
  return repo.watchRelationships().map((all) {
    for (final friend in all) {
      if (friend.id == userId) {
        return friend;
      }
    }
    return null;
  });
}
