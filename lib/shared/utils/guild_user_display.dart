import 'package:flutter/material.dart';
import 'package:fluxer_app/core/constants/media_proxy_sizes.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/media/fluxer_media_url.dart';
import 'package:fluxer_dart/export.dart';

const int guildProfileDefaultAccentColor = 0x4641D9;
const int guildProfileAvatarUnsetFlag = 1 << 0;
const int guildProfileBannerUnsetFlag = 1 << 1;

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
      ? FluxerMediaUrl.guildMemberMedia(
          guildId: guildId,
          userId: user.id,
          type: GuildMemberMediaType.avatar,
          hash: memberAvatar,
        )
      : FluxerMediaUrl.userAvatar(
          userId: user.id,
          hash: fallbackAvatarHash ?? user.avatar,
          size: MediaProxySizes.avatarProfile,
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
      ? FluxerMediaUrl.guildMemberMedia(
          guildId: guildId,
          userId: userId,
          type: GuildMemberMediaType.avatar,
          hash: memberAvatar,
          animated: animatedAvatar,
        )
      : FluxerMediaUrl.userAvatar(
          userId: userId,
          hash: fallbackAvatarHash,
          size: MediaProxySizes.avatarProfile,
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
      ? FluxerMediaUrl.guildMemberMedia(
          guildId: guildId,
          userId: user.id,
          type: GuildMemberMediaType.avatar,
          hash: guildAvatar,
        )
      : FluxerMediaUrl.userAvatar(
          userId: user.id,
          hash: user.avatar,
          size: MediaProxySizes.avatarProfile,
        );
  final String? bannerUrl = isBannerUnset
      ? null
      : guildBanner != null && guildId != null
      ? FluxerMediaUrl.guildMemberMedia(
          guildId: guildId,
          userId: user.id,
          type: GuildMemberMediaType.banner,
          hash: guildBanner,
          size: MediaProxySizes.profileBannerModal,
        )
      : FluxerMediaUrl.userBanner(
          userId: user.id,
          hash: response.userProfile.banner,
          animated: true,
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
