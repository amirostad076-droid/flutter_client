import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/dm/domain/dm_conversation.dart';
import 'package:fluxeron/features/dm/providers/dm_providers.dart';
import 'package:fluxeron/features/friends/domain/friend.dart';
import 'package:fluxeron/features/friends/providers/friend_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'dm_view_model.g.dart';

enum FriendsTab { online, all, pending, blocked }

class DmViewState {
  static const _unset = Object();

  final List<DmConversation> conversations;
  final List<Friend> friendsList;
  final FriendsTab activeTab;
  final String? selectedConversationId;
  final String searchQuery;
  final bool isLoading;
  final String? errorMessage;

  const DmViewState({
    required this.conversations,
    required this.friendsList,
    required this.activeTab,
    required this.selectedConversationId,
    required this.searchQuery,
    required this.isLoading,
    required this.errorMessage,
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

  DmViewState copyWith({
    List<DmConversation>? conversations,
    List<Friend>? friendsList,
    FriendsTab? activeTab,
    Object? selectedConversationId = _unset,
    String? searchQuery,
    bool? isLoading,
    Object? errorMessage = _unset,
  }) {
    return DmViewState(
      conversations: conversations ?? this.conversations,
      friendsList: friendsList ?? this.friendsList,
      activeTab: activeTab ?? this.activeTab,
      selectedConversationId: selectedConversationId == _unset
          ? this.selectedConversationId
          : selectedConversationId as String?,
      searchQuery: searchQuery ?? this.searchQuery,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

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
        debugPrint('[DmViewModel] DM watch error: $error');
      },
    );

    unawaited(_friendSub?.cancel());
    _friendSub = friendRepo.watchRelationships().listen(
      (friends) {
        state = state.copyWith(friendsList: friends);
      },
      onError: (Object error) {
        debugPrint('[DmViewModel] Friends watch error: $error');
      },
    );

    ref.onDispose(() {
      unawaited(_dmSub?.cancel());
      unawaited(_friendSub?.cancel());
    });

    unawaited(Future<void>.microtask(_loadData));
    return const DmViewState(
      conversations: [],
      friendsList: [],
      activeTab: FriendsTab.online,
      selectedConversationId: null,
      searchQuery: '',
      isLoading: true,
      errorMessage: null,
    );
  }

  Future<void> _loadData() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final dmRepo = ref.read(dmRepositoryProvider);
      final friendRepo = ref.read(friendRepositoryProvider);
      await Future.wait([
        dmRepo.getDmChannels(),
        friendRepo.getRelationships(),
      ]);
      state = state.copyWith(isLoading: false);
    } on Exception catch (e) {
      debugPrint('[DmViewModel] Failed to load data: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load conversations',
      );
    }
  }

  Future<void> refresh() => _loadData();

  void selectTab(FriendsTab tab) {
    state = state.copyWith(activeTab: tab);
  }

  void selectConversation(String id) {
    state = state.copyWith(selectedConversationId: id);
  }

  void updateSearch(String query) {
    state = state.copyWith(searchQuery: query);
  }
}
