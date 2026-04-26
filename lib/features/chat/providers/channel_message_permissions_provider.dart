import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'channel_message_permissions_provider.g.dart';

/// Effective flags for the message composer. Uses merged guild role bits only;
/// channel permission overwrites from the API are not stored locally yet.
class ChannelMessagePermissions {
  final bool canSendMessages;
  final bool canAttachFiles;
  final bool canEmbedLinks;

  const ChannelMessagePermissions({
    required this.canSendMessages,
    required this.canAttachFiles,
    required this.canEmbedLinks,
  });

  static const ChannelMessagePermissions none = ChannelMessagePermissions(
    canSendMessages: false,
    canAttachFiles: false,
    canEmbedLinks: false,
  );

  static const ChannelMessagePermissions all = ChannelMessagePermissions(
    canSendMessages: true,
    canAttachFiles: true,
    canEmbedLinks: true,
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
  final conversations = ref.watch(dmViewModelProvider).conversations;
  final channel = await ref.watch(channelByIdProvider(channelId).future);
  if (channel != null && channel.guildId.isNotEmpty) {
    final bits = await ref
        .read(guildPermissionsProvider.notifier)
        .getPermissions(channel.guildId);
    return ChannelMessagePermissions(
      canSendMessages: hasPermission(bits, Permission.sendMessages),
      canAttachFiles: hasPermission(bits, Permission.attachFiles),
      canEmbedLinks: hasPermission(bits, Permission.embedLinks),
    );
  }
  if (findDmById(conversations, channelId) != null) {
    return ChannelMessagePermissions.all;
  }
  return ChannelMessagePermissions.all;
}
