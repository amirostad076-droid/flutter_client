import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/shared/utils/guild_user_display.dart';
import 'package:fluxer_dart/export.dart';

void main() {
  group('resolveGuildUserDisplayFromProfile', () {
    test('uses global profile when guild data is absent', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(userPronouns: 'they/them'),
        guildId: null,
        relationshipNickname: null,
      );
      expect(actual.displayName, 'Global Name');
      expect(actual.avatarUrl, contains('/avatars/1/user_avatar.webp'));
      expect(actual.bannerUrl, contains('/banners/1/user_banner.webp'));
      expect(actual.bio, 'global bio');
      expect(actual.pronouns, 'they/them');
    });

    test('uses guild nickname, avatar, banner, and bio', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(
          userPronouns: 'she/her',
          guildMember: _guildMember(nick: 'Guild Nick', avatar: 'guild_avatar'),
          guildProfile: _guildProfile(
            bio: 'guild bio',
            banner: 'guild_banner',
            pronouns: 'xe/xem',
          ),
        ),
        guildId: '10',
        relationshipNickname: null,
      );
      expect(actual.displayName, 'Guild Nick');
      expect(
        actual.avatarUrl,
        contains('/guilds/10/users/1/avatars/guild_avatar.webp'),
      );
      expect(
        actual.bannerUrl,
        contains('/guilds/10/users/1/banners/guild_banner.webp'),
      );
      expect(actual.bio, 'guild bio');
      expect(actual.pronouns, 'xe/xem');
    });

    test('uses animated global avatar and banner urls', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(userAvatar: 'a_user_avatar', userBanner: 'a_banner'),
        guildId: null,
        relationshipNickname: null,
      );
      expect(
        actual.avatarUrl,
        contains('/avatars/1/a_user_avatar.gif?animated=true&size='),
      );
      expect(
        actual.bannerUrl,
        contains('/banners/1/a_banner.gif?animated=true&size='),
      );
    });

    test('uses animated guild avatar and banner urls', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(
          guildMember: _guildMember(avatar: 'a_guild_avatar'),
          guildProfile: _guildProfile(banner: 'a_guild_banner'),
        ),
        guildId: '10',
        relationshipNickname: null,
      );
      expect(
        actual.avatarUrl,
        contains(
          '/guilds/10/users/1/avatars/a_guild_avatar.gif?animated=true&size=',
        ),
      );
      expect(
        actual.bannerUrl,
        contains(
          '/guilds/10/users/1/banners/a_guild_banner.gif?animated=true&size=',
        ),
      );
    });

    test('relationship nickname overrides guild nickname', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(guildMember: _guildMember(nick: 'Guild Nick')),
        guildId: '10',
        relationshipNickname: 'Friend Nick',
      );
      expect(actual.displayName, 'Friend Nick');
    });

    test('avatar unset forces default avatar fallback', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(
          guildMember: _guildMember(
            avatar: 'guild_avatar',
            profileFlags: guildProfileAvatarUnsetFlag,
          ),
        ),
        guildId: '10',
        relationshipNickname: null,
      );
      expect(actual.avatarUrl, isNull);
    });

    test('banner unset removes image and profile banner color', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(
          guildMember: _guildMember(profileFlags: guildProfileBannerUnsetFlag),
          guildProfile: _guildProfile(banner: 'guild_banner'),
        ),
        guildId: '10',
        relationshipNickname: null,
      );
      expect(actual.bannerUrl, isNull);
      expect(actual.bannerColor, const Color(0xFF112233));
    });

    test('guild profile bio falls back to global bio', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(guildProfile: _guildProfile()),
        guildId: '10',
        relationshipNickname: null,
      );
      expect(actual.bio, 'global bio');
    });

    test('guild profile pronouns fall back to global pronouns', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(
          userPronouns: 'she/her',
          guildMember: _guildMember(),
          guildProfile: _guildProfile(pronouns: null),
        ),
        guildId: '10',
        relationshipNickname: null,
      );
      expect(actual.pronouns, 'she/her');
    });

    test('showGlobalProfile uses global pronouns only', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromProfile(
        response: _profile(
          userPronouns: 'they/them',
          guildMember: _guildMember(),
          guildProfile: _guildProfile(pronouns: 'he/him'),
        ),
        guildId: '10',
        relationshipNickname: null,
        showGlobalProfile: true,
      );
      expect(actual.pronouns, 'they/them');
    });
  });

  group('resolveGuildUserDisplayFromMessage', () {
    test('can force animated avatar hashes to static urls', () {
      final GuildUserDisplay actual = resolveGuildUserDisplayFromMessage(
        userId: '1',
        fallbackDisplayName: 'User',
        fallbackAvatarHash: 'a_avatar',
        fallbackAvatarColor: null,
        member: null,
        guildId: null,
        animatedAvatar: false,
      );
      expect(actual.avatarUrl, contains('/avatars/1/avatar.webp'));
      expect(actual.avatarUrl, isNot(contains('animated=true')));
    });
  });
}

UserProfileFullResponse _profile({
  GuildMemberResponse? guildMember,
  UserProfileFullResponseGuildMemberProfile? guildProfile,
  String? userAvatar,
  String? userBanner,
  String? userPronouns,
}) {
  return UserProfileFullResponse(
    user: UserProfileFullResponseUser(
      id: '1',
      username: 'user',
      discriminator: '0001',
      globalName: 'Global Name',
      avatar: userAvatar ?? 'user_avatar',
      avatarColor: 0x112233,
      flags: 0,
    ),
    userProfile: UserProfileFullResponseUserProfile(
      bio: 'global bio',
      pronouns: userPronouns,
      banner: userBanner ?? 'user_banner',
      bannerColor: 0x445566,
      accentColor: 0x778899,
    ),
    guildMember: guildMember,
    guildMemberProfile: guildProfile,
  );
}

GuildMemberResponse _guildMember({
  String? nick,
  String? avatar,
  int? profileFlags,
}) {
  return GuildMemberResponse(
    user: const UserPartialResponse(
      id: '1',
      username: 'user',
      discriminator: '0001',
      globalName: 'Global Name',
      avatar: 'user_avatar',
      avatarColor: 0x112233,
      flags: 0,
    ),
    roles: const <String>[],
    joinedAt: DateTime.utc(2024),
    mute: false,
    deaf: false,
    nick: nick,
    avatar: avatar,
    profileFlags: profileFlags,
  );
}

UserProfileFullResponseGuildMemberProfile _guildProfile({
  String? bio,
  String? banner,
  String? pronouns,
}) {
  return UserProfileFullResponseGuildMemberProfile(
    bio: bio,
    pronouns: pronouns,
    banner: banner,
    accentColor: 0x112233,
  );
}
