import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/members/domain/member.dart';
import 'package:fluxeron/features/members/providers/member_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_list_view_model.g.dart';

class MemberListViewState {
  static const _unset = Object();

  final List<RoleGroup> roleGroups;
  final bool isLoading;
  final String? errorMessage;
  final String? selectedServerId;

  const MemberListViewState({
    required this.roleGroups,
    required this.isLoading,
    required this.errorMessage,
    required this.selectedServerId,
  });

  MemberListViewState copyWith({
    List<RoleGroup>? roleGroups,
    bool? isLoading,
    Object? errorMessage = _unset,
    Object? selectedServerId = _unset,
  }) {
    return MemberListViewState(
      roleGroups: roleGroups ?? this.roleGroups,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
      selectedServerId: selectedServerId == _unset
          ? this.selectedServerId
          : selectedServerId as String?,
    );
  }
}

@Riverpod(keepAlive: true)
class MemberListViewModel extends _$MemberListViewModel {
  StreamSubscription<List<Member>>? _subscription;

  @override
  MemberListViewState build() {
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    return const MemberListViewState(
      roleGroups: [],
      isLoading: false,
      errorMessage: null,
      selectedServerId: null,
    );
  }

  Future<void> loadMembers(String serverId) async {
    if (serverId == state.selectedServerId && state.roleGroups.isNotEmpty) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      selectedServerId: serverId,
    );

    final repo = ref.read(memberRepositoryProvider);

    unawaited(_subscription?.cancel());
    _subscription = repo
        .watchMembers(serverId)
        .listen(
          (members) {
            final grouped = groupMembersIntoRoles(members);
            state = state.copyWith(roleGroups: grouped, isLoading: false);
          },
          onError: (Object error) {
            debugPrint('[MemberListViewModel] Watch error: $error');
          },
        );

    try {
      await repo.getRoles(serverId);
    } on Exception catch (e) {
      debugPrint('[MemberListViewModel] Failed to load roles: $e');
    }

    try {
      await repo.getMembers(serverId);
    } on Exception catch (e) {
      debugPrint('[MemberListViewModel] Failed to load members: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load members',
      );
    }
  }

  Future<void> refresh() async {
    final serverId = state.selectedServerId;
    if (serverId == null) {
      return;
    }
    state = state.copyWith(selectedServerId: null);
    await loadMembers(serverId);
  }
}
