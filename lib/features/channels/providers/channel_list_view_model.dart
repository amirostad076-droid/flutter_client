import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_list_view_model.g.dart';

class ChannelListState {
  final String serverName;
  final List<ChannelCategory> categories;
  final String? selectedChannelId;
  final Set<String> collapsedCategories;
  final bool isMemberListVisible;

  const ChannelListState({
    required this.serverName,
    required this.categories,
    required this.selectedChannelId,
    required this.collapsedCategories,
    this.isMemberListVisible = true,
  });

  ChannelListState copyWith({
    String? serverName,
    List<ChannelCategory>? categories,
    String? selectedChannelId,
    Set<String>? collapsedCategories,
    bool? isMemberListVisible,
  }) {
    return ChannelListState(
      serverName: serverName ?? this.serverName,
      categories: categories ?? this.categories,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
      collapsedCategories: collapsedCategories ?? this.collapsedCategories,
      isMemberListVisible: isMemberListVisible ?? this.isMemberListVisible,
    );
  }
}

@Riverpod(keepAlive: true)
class ChannelListViewModel extends _$ChannelListViewModel {
  String? _currentGuildId;
  StreamSubscription<List<Channel>>? _subscription;

  @override
  ChannelListState build() {
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    return const ChannelListState(
      serverName: '',
      categories: [],
      selectedChannelId: null,
      collapsedCategories: {},
    );
  }

  void loadChannels(String guildId, {String? serverName}) {
    if (_currentGuildId == guildId) {
      if (serverName != null) {
        state = state.copyWith(serverName: serverName);
      }
      return;
    }
    _currentGuildId = guildId;
    state = state.copyWith(
      serverName: serverName ?? state.serverName,
      collapsedCategories: {},
    );

    final repo = ref.read(channelRepositoryProvider);
    unawaited(_subscription?.cancel());
    _subscription = repo
        .watchChannels(guildId)
        .listen(
          (channels) {
            final categories = groupChannelsIntoCategories(channels);
            state = state.copyWith(categories: categories);
          },
          onError: (Object error) {
            debugPrint('[ChannelListViewModel] Watch error: $error');
          },
        );
  }

  void selectChannel(String channelId) {
    state = state.copyWith(selectedChannelId: channelId);
  }

  void setServerName(String name) {
    state = state.copyWith(serverName: name);
  }

  void toggleMemberList() {
    state = state.copyWith(isMemberListVisible: !state.isMemberListVisible);
  }

  void toggleCategory(String categoryId) {
    final collapsed = <String>{...state.collapsedCategories};
    if (collapsed.contains(categoryId)) {
      collapsed.remove(categoryId);
    } else {
      collapsed.add(categoryId);
    }
    state = state.copyWith(collapsedCategories: collapsed);
  }
}
