import 'dart:async';

import 'package:fluxer_app/features/friends/data/friend_repository.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_relationship_provider.g.dart';

@riverpod
Stream<Friend?> userRelationship(Ref ref, {required String userId}) {
  final FriendRepository repo = ref.watch(friendRepositoryProvider);
  return repo.watchRelationships().map((List<Friend> all) {
    for (final Friend friend in all) {
      if (friend.id == userId) {
        return friend;
      }
    }
    return null;
  });
}
