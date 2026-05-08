import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/guilds/providers/guild_list_view_model.dart';
import 'package:fluxer_app/features/members/providers/member_providers.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_message_permissions_provider.g.dart';

/// Effective flags for the message composer from guild base bits, roles, and
/// channel/category permission overwrites stored on local channel rows.
class ChannelMessagePermissions {
  final bool canSendMessages;
  final bool canAttachFiles;
  final bool canEmbedLinks;
  final bool canUseExternalEmojis;
  final bool canUseExternalStickers;

  const ChannelMessagePermissions({
    required this.canSendMessages,
    required this.canAttachFiles,
    required this.canEmbedLinks,
    required this.canUseExternalEmojis,
    required this.canUseExternalStickers,
  });

  static const ChannelMessagePermissions none = ChannelMessagePermissions(
    canSendMessages: false,
    canAttachFiles: false,
    canEmbedLinks: false,
    canUseExternalEmojis: false,
    canUseExternalStickers: false,
  );

  static const ChannelMessagePermissions all = ChannelMessagePermissions(
    canSendMessages: true,
    canAttachFiles: true,
    canEmbedLinks: true,
    canUseExternalEmojis: true,
    canUseExternalStickers: true,
  );
}

@riverpod
Future<ChannelMessagePermissions> channelMessagePermissions(
  Ref ref,
  String channelId,
) async {
  if (channelId.isEmpty) {
    return ChannelMessagePermissions.none;
  }
  final bool isDmChannel = ref.watch(
    dmViewModelProvider.select(
      (state) => findDmById(state.conversations, channelId) != null,
    ),
  );
  if (isDmChannel) {
    return ChannelMessagePermissions.all;
  }
  await ref.watch(channelPermissionIdentityProvider(channelId).future);
  final channelRow = await ref
      .read(fluxerDatabaseProvider)
      .channelDao
      .getChannelById(channelId);
  if (channelRow == null) {
    return ChannelMessagePermissions.none;
  }
  final Channel channel = Channel.fromRow(channelRow);
  if (channel.guildId.isNotEmpty) {
    final String guildId = channel.guildId;
    ref
      ..watch(guildListViewModelProvider)
      ..watch(guildMemberRowCountProvider(guildId));
    final int bits = await computeEffectiveGuildChannelPermissionBits(
      ref: ref,
      channelId: channelId,
    );
    final bool canSendMessages =
        hasPermission(bits, Permission.sendMessages) ||
        (channel.type == ChannelType.voice &&
            hasPermission(bits, Permission.useTextInVoice));
    return ChannelMessagePermissions(
      canSendMessages: canSendMessages,
      canAttachFiles: hasPermission(bits, Permission.attachFiles),
      canEmbedLinks: hasPermission(bits, Permission.embedLinks),
      canUseExternalEmojis: hasPermission(bits, Permission.useExternalEmojis),
      canUseExternalStickers: hasPermission(
        bits,
        Permission.useExternalStickers,
      ),
    );
  }
  return ChannelMessagePermissions.none;
}

ChannelMessagePermissions channelMessagePermissionsForComposer(
  AsyncValue<ChannelMessagePermissions> async,
) {
  return async.when(
    skipLoadingOnReload: true,
    data: (ChannelMessagePermissions value) => value,
    error: (Object _, StackTrace stackTrace) => ChannelMessagePermissions.none,
    loading: () => ChannelMessagePermissions.none,
  );
}
