import 'package:fluxer_app/core/permissions/channel_permission_resolver.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';

/// True when the @everyone role overwrite fully denies [Permission.viewChannel]
/// (text-like channels) or [Permission.connect] (voice-like)
bool isChannelEveryonePrivateForIcon({
  required ChannelType type,
  required String guildId,
  required String? permissionOverwritesJson,
}) {
  if (guildId.isEmpty) {
    return false;
  }
  final List<ChannelOverwriteEntry> entries =
      parseChannelPermissionOverwritesJson(permissionOverwritesJson);
  ChannelOverwriteEntry? everyoneOverwrite;
  for (final ChannelOverwriteEntry e in entries) {
    if (e.isRoleType && e.id == guildId) {
      everyoneOverwrite = e;
      break;
    }
  }
  if (everyoneOverwrite == null) {
    return false;
  }
  final BigInt deny = everyoneOverwrite.deny;
  switch (type) {
    case ChannelType.voice:
    case ChannelType.stage:
      final BigInt mask = BigInt.from(Permission.connect.value);
      return (deny & mask) == mask;
    case ChannelType.text:
    case ChannelType.announcement:
    case ChannelType.link:
      final BigInt mask = BigInt.from(Permission.viewChannel.value);
      return (deny & mask) == mask;
    case ChannelType.category:
      return false;
  }
}
