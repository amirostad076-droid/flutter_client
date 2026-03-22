import 'package:fluxeron/core/providers/database_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart' show fluxerMediaCdn;
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_view_model.g.dart';

class UserSettingsViewState {
  static const _unset = Object();

  final String userId;
  final String username;
  final String displayName;
  final String discriminator;
  final String? avatar;
  final int? avatarColor;
  final bool messageDisplayCompact;

  const UserSettingsViewState({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.discriminator,
    required this.avatar,
    required this.avatarColor,
    required this.messageDisplayCompact,
  });

  String? get avatarUrl {
    if (avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn'
        '/avatars/$userId/$avatar.png';
  }

  UserSettingsViewState copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? discriminator,
    Object? avatar = _unset,
    Object? avatarColor = _unset,
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
      messageDisplayCompact:
          messageDisplayCompact ?? this.messageDisplayCompact,
    );
  }
}

@Riverpod(keepAlive: true)
class UserSettingsViewModel extends _$UserSettingsViewModel {
  @override
  UserSettingsViewState build() {
    final userId = ref.watch(currentUserIdProvider);
    if (userId != null) {
      _watchUser(userId);
    }

    return UserSettingsViewState(
      userId: userId ?? '',
      username: '',
      displayName: '',
      discriminator: '0',
      avatar: null,
      avatarColor: null,
      messageDisplayCompact: false,
    );
  }

  void _watchUser(String userId) {
    final db = ref.read(fluxerDatabaseProvider);
    final subscription = db.userDao.watchUserById(userId).listen((user) {
      if (user == null) {
        return;
      }
      state = state.copyWith(
        username: user.username,
        displayName: user.globalName ?? user.username,
        discriminator: user.discriminator,
        avatar: user.avatar,
        avatarColor: user.avatarColor,
      );
    });
    ref.onDispose(subscription.cancel);
  }

  void toggleCompact() {
    state = state.copyWith(messageDisplayCompact: !state.messageDisplayCompact);
  }
}
