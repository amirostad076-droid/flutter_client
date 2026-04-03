import 'dart:async';

import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/dm/domain/dm_conversation.dart';
import 'package:fluxer_app/features/dm/providers/dm_providers.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/friends/providers/friend_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dm_view_model.g.dart';

enum FriendsTab { online, all, pending, blocked }

class DmMobileSearchResults {
  final String query;
  final List<DmConversation> conversations;
  final List<Friend> friends;

  const DmMobileSearchResults({
    required this.query,
    required this.conversations,
    required this.friends,
  });

  bool get hasQuery => query.isNotEmpty;
  bool get hasResults => conversations.isNotEmpty || friends.isNotEmpty;
}

class DmViewState {
  final List<DmConversation> conversations;
  final List<Friend> friendsList;
  final FriendsTab activeTab;
  final String searchQuery;

  const DmViewState({
    required this.conversations,
    required this.friendsList,
    required this.activeTab,
    required this.searchQuery,
  });

  List<Friend> get filteredFriends {
    final query = searchQuery.toLowerCase();

    List<Friend> filtered;
    switch (activeTab) {
      case FriendsTab.online:
        filtered = friendsList
            .where(
              (f) =>
                  f.friendStatus == FriendStatus.accepted &&
                  f.status != 'offline',
            )
            .toList();
        if (filtered.isEmpty) {
          filtered = friendsList
              .where((f) => f.friendStatus == FriendStatus.accepted)
              .toList();
        }
      case FriendsTab.all:
        filtered = friendsList
            .where((f) => f.friendStatus == FriendStatus.accepted)
            .toList();
      case FriendsTab.pending:
        filtered = friendsList
            .where(
              (f) =>
                  f.friendStatus == FriendStatus.pendingIncoming ||
                  f.friendStatus == FriendStatus.pendingOutgoing,
            )
            .toList();
      case FriendsTab.blocked:
        filtered = friendsList
            .where((f) => f.friendStatus == FriendStatus.blocked)
            .toList();
    }

    if (query.isNotEmpty) {
      filtered = filtered
          .where((f) => f.username.toLowerCase().contains(query))
          .toList();
    }

    return filtered;
  }

  DmMobileSearchResults mobileSearchResults(
    String rawQuery, {
    List<DmConversation>? conversations,
  }) {
    final query = rawQuery.trim().toLowerCase();
    if (query.isEmpty) {
      return const DmMobileSearchResults(
        query: '',
        conversations: [],
        friends: [],
      );
    }

    final availableConversations = conversations ?? this.conversations;
    final directMessageRecipientIds = availableConversations
        .where((convo) => !convo.isGroup)
        .map((convo) => convo.recipientId)
        .toSet();

    final matchingConversations = availableConversations
        .where((convo) => _matchesConversation(convo, query))
        .toList();
    final matchingFriends =
        friendsList
            .where(
              (friend) =>
                  friend.friendStatus != FriendStatus.blocked &&
                  !directMessageRecipientIds.contains(friend.id) &&
                  _matchesFriend(friend, query),
            )
            .toList()
          ..sort(_sortDiscoverableFriends);

    return DmMobileSearchResults(
      query: rawQuery.trim(),
      conversations: matchingConversations,
      friends: matchingFriends,
    );
  }

  DmViewState copyWith({
    List<DmConversation>? conversations,
    List<Friend>? friendsList,
    FriendsTab? activeTab,
    String? searchQuery,
  }) {
    return DmViewState(
      conversations: conversations ?? this.conversations,
      friendsList: friendsList ?? this.friendsList,
      activeTab: activeTab ?? this.activeTab,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

bool _matchesConversation(DmConversation convo, String query) {
  final haystacks = <String>[
    convo.displayName,
    convo.recipientName,
    convo.lastMessage,
    ...[convo.recipientUsername, convo.lastMessageAuthorName].nonNulls,
    ...convo.groupMembers.map((member) => member.name),
  ];

  return haystacks.any((value) => value.toLowerCase().contains(query));
}

bool _matchesFriend(Friend friend, String query) {
  final haystacks = <String>[
    friend.displayName,
    friend.username,
    ...[friend.nickname].nonNulls,
  ];

  return haystacks.any((value) => value.toLowerCase().contains(query));
}

int _sortDiscoverableFriends(Friend a, Friend b) {
  final rankCompare = _friendSearchRank(
    a.friendStatus,
  ).compareTo(_friendSearchRank(b.friendStatus));
  if (rankCompare != 0) {
    return rankCompare;
  }

  return a.displayName.toLowerCase().compareTo(b.displayName.toLowerCase());
}

int _friendSearchRank(FriendStatus status) => switch (status) {
  FriendStatus.accepted => 0,
  FriendStatus.pendingIncoming => 1,
  FriendStatus.pendingOutgoing => 2,
  FriendStatus.blocked => 3,
};

@Riverpod(keepAlive: true)
class DmViewModel extends _$DmViewModel {
  StreamSubscription<List<DmConversation>>? _dmSub;
  StreamSubscription<List<Friend>>? _friendSub;

  @override
  DmViewState build() {
    final dmRepo = ref.watch(dmRepositoryProvider);
    final friendRepo = ref.watch(friendRepositoryProvider);

    unawaited(_dmSub?.cancel());
    _dmSub = dmRepo.watchDmChannels().listen(
      (convos) {
        state = state.copyWith(conversations: convos);
      },
      onError: (Object error) {
        talker.error('[DmViewModel] DM watch error: $error');
      },
    );

    unawaited(_friendSub?.cancel());
    _friendSub = friendRepo.watchRelationships().listen(
      (friends) {
        state = state.copyWith(friendsList: friends);
      },
      onError: (Object error) {
        talker.error('[DmViewModel] Friends watch error: $error');
      },
    );

    ref.onDispose(() {
      unawaited(_dmSub?.cancel());
      unawaited(_friendSub?.cancel());
    });

    return const DmViewState(
      conversations: [],
      friendsList: [],
      activeTab: FriendsTab.online,
      searchQuery: '',
    );
  }

  void selectTab(FriendsTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }

  Future<void> markAsRead(String channelId) =>
      ref.read(dmRepositoryProvider).markAsRead(channelId);

  Future<bool> closeDmChannel(String channelId) async {
    try {
      await ref.read(dmRepositoryProvider).closeDmChannel(channelId);
      return true;
    } on Exception catch (e) {
      talker.error('[DmViewModel] Failed to close DM: $e');
      return false;
    }
  }
}
