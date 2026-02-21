import 'dart:async';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxeron/core/providers/database_provider.dart';

part 'user_settings_view_model.g.dart';

class UserSettingsViewState {
  static const _unset = Object();

  final String userId;
  final String username;
  final String displayName;
  final String discriminator;
  final String? avatar;
  final int? avatarColor;
  final bool isDarkTheme;
  final bool messageDisplayCompact;

  const UserSettingsViewState({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.discriminator,
    required this.avatar,
    required this.avatarColor,
    required this.isDarkTheme,
    required this.messageDisplayCompact,
  });

  String? get avatarUrl {
    if (avatar == null) {
      return null;
    }
    return 'https://fluxerusercontent.com'
        '/avatars/$userId/$avatar.png';
  }

  UserSettingsViewState copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? discriminator,
    Object? avatar = _unset,
    Object? avatarColor = _unset,
    bool? isDarkTheme,
    bool? messageDisplayCompact,
  }) {
    return UserSettingsViewState(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      displayName: displayName ?? this.displayName,
      discriminator: discriminator ?? this.discriminator,
      avatar: avatar == _unset ? this.avatar : avatar as String?,
      avatarColor: avatarColor == _unset
          ? this.avatarColor
          : avatarColor as int?,
      isDarkTheme: isDarkTheme ?? this.isDarkTheme,
      messageDisplayCompact:
          messageDisplayCompact ?? this.messageDisplayCompact,
    );
  }
}

@Riverpod(keepAlive: true)
class UserSettingsViewModel extends _$UserSettingsViewModel {
  @override
  UserSettingsViewState build() {
    unawaited(Future<void>.microtask(_loadCurrentUser));
    return const UserSettingsViewState(
      userId: '',
      username: '',
      displayName: '',
      discriminator: '0',
      avatar: null,
      avatarColor: null,
      isDarkTheme: true,
      messageDisplayCompact: false,
    );
  }

  Future<void> _loadCurrentUser() async {
    final db = ref.read(fluxerDatabaseProvider);
    final session = await db.authSessionDao.getSession();
    if (session == null) {
      return;
    }
    final user = await db.userDao.getUserById(session.userId);
    if (user == null) {
      return;
    }
    state = state.copyWith(
      userId: user.id,
      username: user.username,
      displayName: user.globalName ?? user.username,
      discriminator: user.discriminator,
      avatar: user.avatar,
      avatarColor: user.avatarColor,
    );
  }

  void toggleTheme() {
    state = state.copyWith(isDarkTheme: !state.isDarkTheme);
  }

  void toggleCompact() {
    state = state.copyWith(messageDisplayCompact: !state.messageDisplayCompact);
  }
}
