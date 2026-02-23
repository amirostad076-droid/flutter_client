import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxeron/features/members/domain/member.dart';
import 'package:fluxeron/features/members/providers/member_providers.dart';
import 'package:fluxeron/features/servers/domain/server.dart';
import 'package:fluxeron/features/servers/providers/server_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'server_settings_view_model.g.dart';

class ServerSettingsViewState {
  final Server? server;
  final List<MemberRole> roles;
  final bool isLoading;

  const ServerSettingsViewState({
    required this.server,
    required this.roles,
    required this.isLoading,
  });

  ServerSettingsViewState copyWith({
    Server? server,
    List<MemberRole>? roles,
    bool? isLoading,
  }) {
    return ServerSettingsViewState(
      server: server ?? this.server,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(keepAlive: true)
class ServerSettingsViewModel extends _$ServerSettingsViewModel {
  @override
  ServerSettingsViewState build() {
    return const ServerSettingsViewState(
      server: null,
      roles: [],
      isLoading: false,
    );
  }

  Future<void> loadServer(String serverId) async {
    state = state.copyWith(isLoading: true);
    try {
      final serverRepo = ref.read(serverRepositoryProvider);
      final server = await serverRepo.getServer(serverId);
      state = state.copyWith(server: server);
      await _loadRoles(serverId);
    } on Exception catch (e) {
      debugPrint(
        '[ServerSettingsViewModel] '
        'Failed to load server: $e',
      );
      state = state.copyWith(isLoading: false);
    }
  }

  Future<void> _loadRoles(String serverId) async {
    try {
      final memberRepo = ref.read(memberRepositoryProvider);
      final roles = await memberRepo.getRoles(serverId);
      state = state.copyWith(roles: roles, isLoading: false);
    } on Exception catch (e) {
      debugPrint(
        '[ServerSettingsViewModel] '
        'Failed to load roles: $e',
      );
      state = state.copyWith(isLoading: false);
    }
  }
}
