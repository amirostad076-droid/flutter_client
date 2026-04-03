import 'dart:async';
import 'dart:convert';

import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/talker.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart'
    show fluxerMediaCdn;
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'user_settings_view_model.g.dart';

class _ResetEdited {
  const _ResetEdited();
}

class UserSettingsViewState {
  static const _unset = Object();
  static const _resetEdited = _ResetEdited();

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

  final String? bio;
  final String? pronouns;
  final int? accentColor;
  final String? banner;
  final String? email;
  final bool verified;
  final bool isProfileLoaded;

  final Object? _editedDisplayName;
  final Object? _editedBio;
  final Object? _editedPronouns;
  final Object? _editedAccentColor;
  final String? editedAvatarBase64;
  final String? editedBannerBase64;
  final bool avatarCleared;
  final bool bannerCleared;

  final bool isSaving;
  final String? error;

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
    this.bio,
    this.pronouns,
    this.accentColor,
    this.banner,
    this.email,
    this.verified = false,
    this.isProfileLoaded = false,
    Object? editedDisplayName = _unset,
    Object? editedBio = _unset,
    Object? editedPronouns = _unset,
    Object? editedAccentColor = _unset,
    this.editedAvatarBase64,
    this.editedBannerBase64,
    this.avatarCleared = false,
    this.bannerCleared = false,
    this.isSaving = false,
    this.error,
  }) : _editedDisplayName = editedDisplayName,
       _editedBio = editedBio,
       _editedPronouns = editedPronouns,
       _editedAccentColor = editedAccentColor;

  String? get editedDisplayName =>
      _editedDisplayName == _unset ? null : _editedDisplayName as String?;
  bool get isEditedDisplayNameSet => _editedDisplayName != _unset;

  String? get editedBio => _editedBio == _unset ? null : _editedBio as String?;
  bool get isEditedBioSet => _editedBio != _unset;

  String? get editedPronouns =>
      _editedPronouns == _unset ? null : _editedPronouns as String?;
  bool get isEditedPronounsSet => _editedPronouns != _unset;

  int? get editedAccentColor =>
      _editedAccentColor == _unset ? null : _editedAccentColor as int?;
  bool get isEditedAccentColorSet => _editedAccentColor != _unset;

  String? get avatarUrl {
    if (avatar == null) {
      return null;
    }
    return '$fluxerMediaCdn'
        '/avatars/$userId/$avatar.png';
  }

  String? get bannerUrl {
    if (banner == null) {
      return null;
    }
    return '$fluxerMediaCdn'
        '/banners/$userId/$banner.png';
  }

  DateTime get resolvedMemberSince {
    final DateTime? stored = memberSince;
    if (stored != null) {
      return stored;
    }
    return dateTimeFromUserSnowflakeOrNull(userId) ??
        DateTime.fromMillisecondsSinceEpoch(kSnowflakeEpochMs, isUtc: true);
  }

  bool get isDirty {
    if (isEditedDisplayNameSet && editedDisplayName != displayName) {
      return true;
    }
    if (isEditedBioSet && editedBio != bio) {
      return true;
    }
    if (isEditedPronounsSet && editedPronouns != pronouns) {
      return true;
    }
    if (isEditedAccentColorSet && editedAccentColor != accentColor) {
      return true;
    }
    if (editedAvatarBase64 != null || avatarCleared) {
      return true;
    }
    if (editedBannerBase64 != null || bannerCleared) {
      return true;
    }
    return false;
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
    Object? bio = _unset,
    Object? pronouns = _unset,
    Object? accentColor = _unset,
    Object? banner = _unset,
    Object? email = _unset,
    bool? verified,
    bool? isProfileLoaded,
    Object? editedDisplayName = _unset,
    Object? editedBio = _unset,
    Object? editedPronouns = _unset,
    Object? editedAccentColor = _unset,
    Object? editedAvatarBase64 = _unset,
    Object? editedBannerBase64 = _unset,
    bool? avatarCleared,
    bool? bannerCleared,
    bool? isSaving,
    Object? error = _unset,
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
      bio: bio == _unset ? this.bio : bio as String?,
      pronouns: pronouns == _unset ? this.pronouns : pronouns as String?,
      accentColor: accentColor == _unset
          ? this.accentColor
          : accentColor as int?,
      banner: banner == _unset ? this.banner : banner as String?,
      email: email == _unset ? this.email : email as String?,
      verified: verified ?? this.verified,
      isProfileLoaded: isProfileLoaded ?? this.isProfileLoaded,
      editedDisplayName: editedDisplayName == _unset
          ? _editedDisplayName
          : editedDisplayName == _resetEdited
          ? _unset
          : editedDisplayName,
      editedBio: editedBio == _unset
          ? _editedBio
          : editedBio == _resetEdited
          ? _unset
          : editedBio,
      editedPronouns: editedPronouns == _unset
          ? _editedPronouns
          : editedPronouns == _resetEdited
          ? _unset
          : editedPronouns,
      editedAccentColor: editedAccentColor == _unset
          ? _editedAccentColor
          : editedAccentColor == _resetEdited
          ? _unset
          : editedAccentColor,
      editedAvatarBase64: editedAvatarBase64 == _unset
          ? this.editedAvatarBase64
          : editedAvatarBase64 as String?,
      editedBannerBase64: editedBannerBase64 == _unset
          ? this.editedBannerBase64
          : editedBannerBase64 as String?,
      avatarCleared: avatarCleared ?? this.avatarCleared,
      bannerCleared: bannerCleared ?? this.bannerCleared,
      isSaving: isSaving ?? this.isSaving,
      error: error == _unset ? this.error : error as String?,
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
      unawaited(loadProfile());
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

  Future<void> loadProfile() async {
    try {
      final client = ref.read(fluxerClientProvider);
      final profile = await client.users.getCurrentUser();
      state = state.copyWith(
        bio: profile.bio,
        pronouns: profile.pronouns,
        accentColor: profile.accentColor,
        banner: profile.banner,
        email: profile.email,
        verified: profile.verified,
        isProfileLoaded: true,
      );
    } on Exception catch (e) {
      talker.error('Failed to load profile', e);
      state = state.copyWith(error: 'Failed to load profile');
    }
  }

  void updateDisplayName(String value) {
    state = state.copyWith(editedDisplayName: value);
  }

  void updateBio(String value) {
    state = state.copyWith(editedBio: value);
  }

  void updatePronouns(String value) {
    state = state.copyWith(editedPronouns: value);
  }

  void updateAccentColor(int value) {
    state = state.copyWith(editedAccentColor: value);
  }

  void setAvatar(String base64) {
    state = state.copyWith(editedAvatarBase64: base64, avatarCleared: false);
  }

  void clearAvatar() {
    state = state.copyWith(avatarCleared: true, editedAvatarBase64: null);
  }

  void setBanner(String base64) {
    state = state.copyWith(editedBannerBase64: base64, bannerCleared: false);
  }

  void clearBanner() {
    state = state.copyWith(bannerCleared: true, editedBannerBase64: null);
  }

  Future<void> save() async {
    if (!state.isDirty) {
      return;
    }

    state = state.copyWith(isSaving: true, error: null);

    try {
      final s = state;

      String? globalName;
      if (s.isEditedDisplayNameSet && s.editedDisplayName != s.displayName) {
        globalName = s.editedDisplayName;
      }

      String? bio;
      if (s.isEditedBioSet && s.editedBio != s.bio) {
        bio = s.editedBio;
      }

      String? pronouns;
      if (s.isEditedPronounsSet && s.editedPronouns != s.pronouns) {
        pronouns = s.editedPronouns;
      }

      int? accentColor;
      if (s.isEditedAccentColorSet && s.editedAccentColor != s.accentColor) {
        accentColor = s.editedAccentColor;
      }

      String? avatarValue;
      if (s.editedAvatarBase64 != null) {
        avatarValue = s.editedAvatarBase64;
      }

      String? bannerValue;
      if (s.editedBannerBase64 != null) {
        bannerValue = s.editedBannerBase64;
      }

      final client = ref.read(fluxerClientProvider);
      await client.users.updateCurrentUser(
        body: UserUpdateWithVerificationRequest(
          globalName: globalName,
          bio: bio,
          pronouns: pronouns,
          accentColor: accentColor,
          avatar: s.avatarCleared ? null : avatarValue,
          banner: s.bannerCleared ? null : bannerValue,
        ),
      );

      await loadProfile();
      reset();
    } on Exception catch (e) {
      talker.error('Failed to save profile', e);
      state = state.copyWith(isSaving: false, error: 'Failed to save profile');
    }
  }

  void reset() {
    state = state.copyWith(
      editedDisplayName: UserSettingsViewState._resetEdited,
      editedBio: UserSettingsViewState._resetEdited,
      editedPronouns: UserSettingsViewState._resetEdited,
      editedAccentColor: UserSettingsViewState._resetEdited,
      editedAvatarBase64: null,
      editedBannerBase64: null,
      avatarCleared: false,
      bannerCleared: false,
      isSaving: false,
      error: null,
    );
  }

  void toggleCompact() {
    state = state.copyWith(messageDisplayCompact: !state.messageDisplayCompact);
  }
}
