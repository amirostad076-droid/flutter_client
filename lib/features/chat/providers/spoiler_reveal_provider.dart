import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'spoiler_reveal_provider.g.dart';

@riverpod
Future<bool> spoilerAutoReveal(Ref ref, String channelId) async {
  if (channelId.isEmpty) {
    return false;
  }

  final bits = await computeEffectiveGuildChannelPermissionBits(
    ref: ref,
    channelId: channelId,
  );
  return hasPermission(bits, Permission.manageMessages);
}
