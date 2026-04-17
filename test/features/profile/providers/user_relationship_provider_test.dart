import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/features/friends/data/friend_repository.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:fluxer_app/features/profile/providers/user_relationship_provider.dart';

class _FakeFriendRepository implements FriendRepository {
  _FakeFriendRepository(this._friends);
  final List<Friend> _friends;

  @override
  Stream<List<Friend>> watchRelationships() => Stream.value(_friends);

  @override
  dynamic noSuchMethod(Invocation invocation) =>
      super.noSuchMethod(invocation);
}

void main() {
  test('emits matching friend when present', () async {
    const friend = Friend(
      id: '123',
      username: 'alice',
      friendStatus: FriendStatus.blocked,
    );
    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(
          _FakeFriendRepository([friend]),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(
      userRelationshipProvider(userId: '123'),
      (_, _) {},
    );
    addTearDown(sub.close);

    final result = await container
        .read(userRelationshipProvider(userId: '123').future);
    expect(result?.id, '123');
    expect(result?.friendStatus, FriendStatus.blocked);
  });

  test('emits null when no matching friend', () async {
    final container = ProviderContainer(
      overrides: [
        friendRepositoryProvider.overrideWithValue(
          _FakeFriendRepository(const []),
        ),
      ],
    );
    addTearDown(container.dispose);

    final sub = container.listen(
      userRelationshipProvider(userId: 'missing'),
      (_, _) {},
    );
    addTearDown(sub.close);

    final result = await container
        .read(userRelationshipProvider(userId: 'missing').future);
    expect(result, isNull);
  });
}
