import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/features/members/domain/member.dart';
import 'package:fluxer_app/features/members/providers/member_providers.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_providers.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'guild_settings_view_model.g.dart';

class GuildSettingsViewState {
  final Guild? guild;
  final List<MemberRole> roles;
  final bool isLoading;

  const GuildSettingsViewState({
    required this.guild,
    required this.roles,
    required this.isLoading,
  });

  GuildSettingsViewState copyWith({
    Guild? guild,
    List<MemberRole>? roles,
    bool? isLoading,
  }) {
    return GuildSettingsViewState(
      guild: guild ?? this.guild,
      roles: roles ?? this.roles,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

@Riverpod(keepAlive: true)
class GuildSettingsViewModel extends _$GuildSettingsViewModel {
  @override
  GuildSettingsViewState build() {
    return const GuildSettingsViewState(
      guild: null,
      roles: [],
      isLoading: false,
    );
  }

  Future<void> loadServer(String serverId) async {
    state = state.copyWith(isLoading: true);
    try {
      final guildRepo = ref.read(guildRepositoryProvider);
      final guild = await guildRepo.getServer(serverId);
      state = state.copyWith(guild: guild);
      await _loadRoles(serverId);
    } on Exception catch (e) {
      debugPrint(
        '[GuildSettingsViewModel] '
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
        '[GuildSettingsViewModel] '
        'Failed to load roles: $e',
      );
      state = state.copyWith(isLoading: false);
    }
  }
}
