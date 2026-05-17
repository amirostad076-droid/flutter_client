import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/channel_permission_cache_provider.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/providers/channel_message_permissions_provider.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/settings/providers/user_settings_view_model.dart';

UserSettingsViewState _testUserSettings({required String userId}) {
  return UserSettingsViewState(
    userId: userId,
    username: 'user',
    displayName: 'user',
    discriminator: '0001',
    avatar: null,
    avatarColor: null,
    memberSince: null,
    status: 'online',
    messageDisplayCompact: false,
    developerMode: false,
    trustedDomains: const <String>[],
  );
}

class _EmptyGuildListViewModel extends GuildListViewModel {
  @override
  GuildListViewState build() => const GuildListViewState(guilds: <Guild>[]);
}

class _FixedUserSettingsViewModel extends UserSettingsViewModel {
  _FixedUserSettingsViewModel(this._userId);

  final String _userId;

  @override
  UserSettingsViewState build() => _testUserSettings(userId: _userId);
}

void main() {
  group('channelMessagePermissionsForComposer', () {
    test('loading maps to unresolved not deny', () {
      final ChannelMessagePermissions perms =
          channelMessagePermissionsForComposer(
            const AsyncValue<ChannelMessagePermissions>.loading(),
          );
      expect(perms, ChannelMessagePermissions.unresolved);
      expect(perms.isComposerEnabled, isTrue);
      expect(perms.showsNoSendPermissionHint, isFalse);
    });

    test('error maps to unresolved not deny', () {
      final ChannelMessagePermissions perms =
          channelMessagePermissionsForComposer(
            AsyncValue<ChannelMessagePermissions>.error(
              Exception('test'),
              StackTrace.empty,
            ),
          );
      expect(perms, ChannelMessagePermissions.unresolved);
      expect(perms.showsNoSendPermissionHint, isFalse);
    });

    test('resolved deny shows permission hint flag', () {
      final ChannelMessagePermissions perms =
          channelMessagePermissionsForComposer(
            const AsyncValue.data(ChannelMessagePermissions.none),
          );
      expect(perms.isComposerEnabled, isFalse);
      expect(perms.showsNoSendPermissionHint, isTrue);
      expect(perms.canShowAttachControls, isFalse);
      expect(perms.isVoiceEnabled, isFalse);
    });

    test('unresolved keeps attach and voice aligned with input', () {
      const ChannelMessagePermissions perms =
          ChannelMessagePermissions.unresolved;
      expect(perms.isComposerEnabled, isTrue);
      expect(perms.canShowAttachControls, isTrue);
      expect(perms.isVoiceEnabled, isTrue);
    });

    test('resolved send without attach hides attach controls', () {
      const ChannelMessagePermissions perms = ChannelMessagePermissions(
        isResolved: true,
        canSendMessages: true,
        canAttachFiles: false,
        canEmbedLinks: true,
        canUseExternalEmojis: true,
        canUseExternalStickers: true,
      );
      expect(perms.isComposerEnabled, isTrue);
      expect(perms.canShowAttachControls, isFalse);
      expect(perms.isVoiceEnabled, isTrue);
    });

    test('reload keeps previous data instead of loading deny', () {
      const ChannelMessagePermissions allowed = ChannelMessagePermissions.all;
      final ChannelMessagePermissions perms =
          channelMessagePermissionsForComposer(
            const AsyncValue<ChannelMessagePermissions>.loading()
                .copyWithPrevious(const AsyncValue.data(allowed)),
          );
      expect(perms, allowed);
    });
  });

  group('channelMessagePermissionsFromBits', () {
    test('maps send and attach flags from effective bits', () {
      final int bits =
          Permission.sendMessages.value | Permission.attachFiles.value;
      final ChannelMessagePermissions perms = channelMessagePermissionsFromBits(
        bits: bits,
        channelType: ChannelType.text,
      );
      expect(perms.isResolved, isTrue);
      expect(perms.canSendMessages, isTrue);
      expect(perms.canAttachFiles, isTrue);
      expect(perms.canEmbedLinks, isFalse);
    });
  });

  group('ChannelPermissionCache', () {
    test('does not cache bits when guild list is not hydrated', () async {
      final FluxerDatabase db = FluxerDatabase.forTesting(
        NativeDatabase.memory(),
      );
      addTearDown(db.close);
      const String guildId = 'guild_1';
      const String channelId = 'channel_1';
      const String userId = 'user_1';
      await db.guildDao.upsertServer(
        ServersCompanion.insert(id: guildId, name: 'Guild'),
      );
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
        ),
      );
      await db.memberDao.upsertMember(
        MembersCompanion.insert(userId: userId, guildId: guildId),
      );

      final ProviderContainer container = ProviderContainer(
        overrides: [
          fluxerDatabaseProvider.overrideWithValue(db),
          guildListViewModelProvider.overrideWith(_EmptyGuildListViewModel.new),
          userSettingsViewModelProvider.overrideWith(
            () => _FixedUserSettingsViewModel(userId),
          ),
        ],
      );
      addTearDown(container.dispose);

      await container
          .read(channelPermissionCacheProvider.notifier)
          .rebuildChannel(channelId);

      expect(
        container
            .read(channelPermissionCacheProvider.notifier)
            .getChannelBits(channelId),
        equals(null),
      );
    });
  });

  group('computeEffectiveGuildChannelPermissionBitsOutcome', () {
    test('returns shouldCache false when guild is missing from list', () async {
      final FluxerDatabase db = FluxerDatabase.forTesting(
        NativeDatabase.memory(),
      );
      addTearDown(db.close);
      const String guildId = 'guild_1';
      const String channelId = 'channel_1';
      await db.channelDao.upsertChannel(
        ChannelsCompanion.insert(
          id: channelId,
          guildId: guildId,
          name: 'general',
        ),
      );

      final ProviderContainer container = ProviderContainer(
        overrides: [
          fluxerDatabaseProvider.overrideWithValue(db),
          guildListViewModelProvider.overrideWith(_EmptyGuildListViewModel.new),
          userSettingsViewModelProvider.overrideWith(
            () => _FixedUserSettingsViewModel('user_1'),
          ),
        ],
      );
      addTearDown(container.dispose);

      final ChannelPermissionBitsOutcome outcome = await container.read(
        FutureProvider<ChannelPermissionBitsOutcome>(
          (Ref ref) => computeEffectiveGuildChannelPermissionBitsOutcome(
            ref: ref,
            channelId: channelId,
          ),
        ).future,
      );

      expect(outcome.shouldCache, isFalse);
      expect(outcome.value, 0);
    });
  });
}
