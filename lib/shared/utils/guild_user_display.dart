import 'package:flutter/material.dart';
import 'package:fluxer_app/core/constants/media_proxy_sizes.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/features/guilds/domain/guild.dart'
    show fluxerMediaCdn;
import 'package:fluxer_dart/export.dart';

const int guildProfileDefaultAccentColor = 0x4641D9;
const int guildProfileAvatarUnsetFlag = 1 << 0;
const int guildProfileBannerUnsetFlag = 1 << 1;

enum GuildMemberMediaType {
  avatar('avatars'),
  banner('banners');

  const GuildMemberMediaType(this.path);

  final String path;
}

class GuildUserDisplay {
  const GuildUserDisplay({
    required this.displayName,
    required this.avatarUrl,
    required this.avatarColor,
    this.bannerUrl,
    this.bannerColor,
    this.bio,
    this.pronouns,
    this.hasGuildProfile = false,
    this.isShowingGlobalProfile = false,
  });

  final String displayName;
  final String? avatarUrl;
  final int? avatarColor;
  final String? bannerUrl;
  final Color? bannerColor;
  final String? bio;
  final String? pronouns;
  final bool hasGuildProfile;
  final bool isShowingGlobalProfile;
}

Color resolveGuildProfileBannerColor({
  required int? bannerColor,
  required int? accentColor,
  required int? avatarColor,
  int defaultAccentColor = guildProfileDefaultAccentColor,
}) {
  final List<int?> candidates = <int?>[bannerColor, accentColor, avatarColor];
  for (final int? candidate in candidates) {
    if (candidate != null) {
      return Color(0xFF000000 | candidate);
    }
  }
  return Color(0xFF000000 | defaultAccentColor);
}

String? buildGlobalUserAvatarUrl({
  required String userId,
  required String? avatarHash,
  int size = MediaProxySizes.avatarProfile,
  bool animated = true,
}) {
  if (avatarHash == null || avatarHash.isEmpty) {
    return null;
  }
  if (animated && isAnimatedMediaHash(avatarHash)) {
    return '$fluxerMediaCdn/avatars/$userId/$avatarHash.gif'
        '?animated=true&size=$size';
  }
  final String hash = normalizeMediaHash(avatarHash);
  return '$fluxerMediaCdn/avatars/$userId/$hash.webp?size=$size';
}

String? buildGlobalUserBannerUrl({
  required String userId,
  required String? bannerHash,
  int size = MediaProxySizes.profileBannerModal,
}) {
  if (bannerHash == null || bannerHash.isEmpty) {
    return null;
  }
  if (isAnimatedMediaHash(bannerHash)) {
    return '$fluxerMediaCdn/banners/$userId/$bannerHash.gif'
        '?animated=true&size=$size';
  }
  final String hash = normalizeMediaHash(bannerHash);
  return '$fluxerMediaCdn/banners/$userId/$hash.webp?size=$size';
}

String buildGuildMemberMediaUrl({
  required String guildId,
  required String userId,
  required GuildMemberMediaType mediaType,
  required String hash,
  required int size,
  bool animated = true,
}) {
  if (animated && isAnimatedMediaHash(hash)) {
    return '$fluxerMediaCdn/guilds/$guildId/users/$userId/${mediaType.path}/'
        '$hash.gif?animated=true&size=$size';
  }
  final String normalizedHash = normalizeMediaHash(hash);
  return '$fluxerMediaCdn/guilds/$guildId/users/$userId/${mediaType.path}/'
      '$normalizedHash.webp?size=$size';
}

bool isAnimatedMediaHash(String hash) => hash.startsWith('a_');

String normalizeMediaHash(String hash) {
  return isAnimatedMediaHash(hash) ? hash.substring(2) : hash;
}

GuildUserDisplay resolveGuildUserDisplayFromRows({
  required db.User user,
  required db.Member? member,
  required String? guildId,
  String? fallbackDisplayName,
  String? fallbackAvatarHash,
  int? fallbackAvatarColor,
}) {
  final String? nick = member?.nick?.trim();
  final String displayName = nick != null && nick.isNotEmpty
      ? nick
      : fallbackDisplayName ?? user.globalName ?? user.username;
  final String? memberAvatar = member?.serverAvatar;
  final String? avatarUrl =
      guildId != null && memberAvatar != null && memberAvatar.isNotEmpty
      ? buildGuildMemberMediaUrl(
          guildId: guildId,
          userId: user.id,
          mediaType: GuildMemberMediaType.avatar,
          hash: memberAvatar,
          size: MediaProxySizes.avatarProfile,
        )
      : buildGlobalUserAvatarUrl(
          userId: user.id,
          avatarHash: fallbackAvatarHash ?? user.avatar,
        );
  return GuildUserDisplay(
    displayName: displayName,
    avatarUrl: avatarUrl,
    avatarColor: fallbackAvatarColor ?? user.avatarColor,
  );
}

GuildUserDisplay resolveGuildUserDisplayFromMessage({
  required String userId,
  required String fallbackDisplayName,
  required String? fallbackAvatarHash,
  required int? fallbackAvatarColor,
  required db.Member? member,
  required String? guildId,
  bool animatedAvatar = true,
}) {
  final String? nick = member?.nick?.trim();
  final String displayName = nick != null && nick.isNotEmpty
      ? nick
      : fallbackDisplayName;
  final String? memberAvatar = member?.serverAvatar;
  final String? avatarUrl =
      guildId != null && memberAvatar != null && memberAvatar.isNotEmpty
      ? buildGuildMemberMediaUrl(
          guildId: guildId,
          userId: userId,
          mediaType: GuildMemberMediaType.avatar,
          hash: memberAvatar,
          size: MediaProxySizes.avatarProfile,
          animated: animatedAvatar,
        )
      : buildGlobalUserAvatarUrl(
          userId: userId,
          avatarHash: fallbackAvatarHash,
          animated: animatedAvatar,
        );
  return GuildUserDisplay(
    displayName: displayName,
    avatarUrl: avatarUrl,
    avatarColor: fallbackAvatarColor,
  );
}

GuildUserDisplay resolveGuildUserDisplayFromProfile({
  required UserProfileFullResponse response,
  required String? guildId,
  required String? relationshipNickname,
  bool showGlobalProfile = false,
}) {
  final UserProfileFullResponseUser user = response.user;
  final GuildMemberResponse? guildMember = response.guildMember;
  final bool canUseGuildProfile =
      guildId != null &&
      !showGlobalProfile &&
      (guildMember != null || response.guildMemberProfile != null);
  final UserProfileFullResponseGuildMemberProfile? guildProfile =
      canUseGuildProfile ? response.guildMemberProfile : null;
  final bool isAvatarUnset =
      canUseGuildProfile &&
      hasGuildProfileFlag(guildMember, guildProfileAvatarUnsetFlag);
  final bool isBannerUnset =
      canUseGuildProfile &&
      hasGuildProfileFlag(guildMember, guildProfileBannerUnsetFlag);
  final String? guildAvatar = guildMember?.avatar;
  final String? guildBanner = guildProfile?.banner;
  final String? avatarUrl = isAvatarUnset
      ? null
      : canUseGuildProfile && guildAvatar != null
      ? buildGuildMemberMediaUrl(
          guildId: guildId,
          userId: user.id,
          mediaType: GuildMemberMediaType.avatar,
          hash: guildAvatar,
          size: MediaProxySizes.avatarProfile,
        )
      : buildGlobalUserAvatarUrl(userId: user.id, avatarHash: user.avatar);
  final String? bannerUrl = isBannerUnset
      ? null
      : guildBanner != null && guildId != null
      ? buildGuildMemberMediaUrl(
          guildId: guildId,
          userId: user.id,
          mediaType: GuildMemberMediaType.banner,
          hash: guildBanner,
          size: MediaProxySizes.profileBannerModal,
        )
      : buildGlobalUserBannerUrl(
          userId: user.id,
          bannerHash: response.userProfile.banner,
        );
  final int? bannerColor = isBannerUnset
      ? null
      : response.userProfile.bannerColor;
  final int? accentColor =
      guildProfile?.accentColor ??
      (canUseGuildProfile ? guildMember?.accentColor : null) ??
      response.userProfile.accentColor;
  return GuildUserDisplay(
    displayName: resolveGuildProfileDisplayName(
      user: user,
      guildMember: guildMember,
      relationshipNickname: relationshipNickname,
      useGuildProfile: canUseGuildProfile,
    ),
    avatarUrl: avatarUrl,
    avatarColor: user.avatarColor,
    bannerUrl: bannerUrl,
    bannerColor: resolveGuildProfileBannerColor(
      bannerColor: bannerColor,
      accentColor: accentColor,
      avatarColor: user.avatarColor,
    ),
    bio: guildProfile?.bio ?? response.userProfile.bio,
    pronouns: guildProfile?.pronouns ?? response.userProfile.pronouns,
    isShowingGlobalProfile: showGlobalProfile,
    hasGuildProfile: response.guildMemberProfile != null && guildId != null,
  );
}

bool hasGuildProfileFlag(GuildMemberResponse? member, int flag) {
  final int? profileFlags = member?.profileFlags;
  return profileFlags != null && (profileFlags & flag) != 0;
}

String resolveGuildProfileDisplayName({
  required UserProfileFullResponseUser user,
  required GuildMemberResponse? guildMember,
  required String? relationshipNickname,
  required bool useGuildProfile,
}) {
  final String? nickname = relationshipNickname?.trim();
  if (nickname != null && nickname.isNotEmpty) {
    return nickname;
  }
  final String? guildNickname = useGuildProfile
      ? guildMember?.nick?.trim()
      : null;
  if (guildNickname != null && guildNickname.isNotEmpty) {
    return guildNickname;
  }
  return user.globalName ?? user.username;
}
