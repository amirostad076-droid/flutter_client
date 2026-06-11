import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/features/members/providers/member_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'member_list_view_model.g.dart';

class MemberListViewState {
  static const _unset = Object();

  final List<RoleGroup> roleGroups;
  final String? selectedGuildId;

  const MemberListViewState({
    required this.roleGroups,
    required this.selectedGuildId,
  });

  MemberListViewState copyWith({
    List<RoleGroup>? roleGroups,
    Object? selectedGuildId = _unset,
  }) {
    return MemberListViewState(
      roleGroups: roleGroups ?? this.roleGroups,
      selectedGuildId: selectedGuildId == _unset
          ? this.selectedGuildId
          : selectedGuildId as String?,
    );
  }
}

@Riverpod(keepAlive: true)
class MemberListViewModel extends _$MemberListViewModel {
  StreamSubscription<List<Member>>? _subscription;

  @override
  MemberListViewState build() {
    ref.onDispose(() => unawaited(_subscription?.cancel()));
    return const MemberListViewState(roleGroups: [], selectedGuildId: null);
  }

  void loadMembers(String guildId, {bool force = false}) {
    if (!force && guildId == state.selectedGuildId) {
      return;
    }

    state = state.copyWith(selectedGuildId: guildId);

    final repo = ref.read(memberRepositoryProvider);

    unawaited(_subscription?.cancel());
    _subscription = repo
        .watchMembers(guildId)
        .listen(
          (members) {
            final grouped = groupMembersIntoRoles(members);
            state = state.copyWith(roleGroups: grouped);
          },
          onError: (Object error) {
            debugPrint('[MemberListViewModel] Watch error: $error');
          },
        );
  }
}
