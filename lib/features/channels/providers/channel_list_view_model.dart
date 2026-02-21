import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:fluxeron/features/channels/providers/channel_providers.dart';

part 'channel_list_view_model.g.dart';

class ChannelListState {
  final String serverName;
  final List<ChannelCategory> categories;
  final String? selectedChannelId;
  final Set<String> collapsedCategories;
  final bool isLoading;
  final bool isMemberListVisible;

  const ChannelListState({
    required this.serverName,
    required this.categories,
    required this.selectedChannelId,
    required this.collapsedCategories,
    required this.isLoading,
    this.isMemberListVisible = true,
  });

  ChannelListState copyWith({
    String? serverName,
    List<ChannelCategory>? categories,
    String? selectedChannelId,
    Set<String>? collapsedCategories,
    bool? isLoading,
    bool? isMemberListVisible,
  }) {
    return ChannelListState(
      serverName: serverName ?? this.serverName,
      categories: categories ?? this.categories,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
      collapsedCategories: collapsedCategories ?? this.collapsedCategories,
      isLoading: isLoading ?? this.isLoading,
      isMemberListVisible: isMemberListVisible ?? this.isMemberListVisible,
    );
  }
}

@Riverpod(keepAlive: true)
class ChannelListViewModel extends _$ChannelListViewModel {
  String? _currentServerId;

  @override
  ChannelListState build() {
    return const ChannelListState(
      serverName: '',
      categories: [],
      selectedChannelId: null,
      collapsedCategories: {},
      isLoading: false,
    );
  }

  Future<void> loadChannels(String serverId, {String? serverName}) async {
    if (_currentServerId == serverId && state.categories.isNotEmpty) {
      return;
    }
    _currentServerId = serverId;
    state = state.copyWith(
      isLoading: true,
      serverName: serverName ?? state.serverName,
      collapsedCategories: {},
    );
    try {
      final repo = ref.read(channelRepositoryProvider);
      final categories = await repo.getChannels(serverId);
      state = state.copyWith(categories: categories, isLoading: false);
    } on Exception catch (e) {
      debugPrint('[ChannelListViewModel] Failed to load channels: $e');
      state = state.copyWith(isLoading: false);
    }
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
