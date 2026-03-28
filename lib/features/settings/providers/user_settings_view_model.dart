import 'dart:convert';

import 'package:riverpod_annotation/riverpod_annotation.dart';

import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart' show fluxerMediaCdn;
import 'package:fluxer_app/shared/utils/snowflake_time.dart';

part 'user_settings_view_model.g.dart';

class UserSettingsViewState {
  static const _unset = Object();

  final String userId;
  final String username;
  final String displayName;
  final String discriminator;
  final String? avatar;
  final int? avatarColor;
  final DateTime? memberSince;
  final String status;
  final bool messageDisplayCompact;
  final bool developerMode;

  const UserSettingsViewState({
    required this.userId,
    required this.username,
    required this.displayName,
    required this.discriminator,
    required this.avatar,
    required this.avatarColor,
    required this.memberSince,
    required this.status,
    required this.messageDisplayCompact,
    required this.developerMode,
  });

  String? get avatarUrl {
    if (avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn'
        '/avatars/$userId/$avatar.png';
  }

  /// Stored member date, or derived from [userId] snowflake, or Fluxer epoch.
  DateTime get resolvedMemberSince {
    final DateTime? stored = memberSince;
    if (stored != null) {
      return stored;
    }
    return dateTimeFromUserSnowflakeOrNull(userId) ??
        DateTime.fromMillisecondsSinceEpoch(kSnowflakeEpochMs, isUtc: true);
  }

  UserSettingsViewState copyWith({
    String? userId,
    String? username,
    String? displayName,
    String? discriminator,
    Object? avatar = _unset,
    Object? avatarColor = _unset,
    Object? memberSince = _unset,
    String? status,
    bool? messageDisplayCompact,
    bool? developerMode,
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
      memberSince: memberSince == _unset
          ? this.memberSince
          : memberSince as DateTime?,
      status: status ?? this.status,
      messageDisplayCompact:
          messageDisplayCompact ?? this.messageDisplayCompact,
      developerMode: developerMode ?? this.developerMode,
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
      _watchSettings(userId);
    }

    return UserSettingsViewState(
      userId: userId ?? '',
      username: '',
      displayName: '',
      discriminator: '0',
      avatar: null,
      avatarColor: null,
      memberSince: null,
      status: 'offline',
      messageDisplayCompact: false,
      developerMode: false,
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

  void _watchSettings(String userId) {
    final db = ref.read(fluxerDatabaseProvider);
    final subscription = db.userSettingsDao.watchSettings(userId).listen((row) {
      if (row == null) {
        return;
      }
      final data = jsonDecode(row.data) as Map<String, dynamic>;
      final developerMode = data['developer_mode'] as bool? ?? false;
      state = state.copyWith(developerMode: developerMode);
    });
    ref.onDispose(subscription.cancel);
  }

  void toggleCompact() {
    state = state.copyWith(messageDisplayCompact: !state.messageDisplayCompact);
  }
}
