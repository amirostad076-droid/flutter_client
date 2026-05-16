import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';

const Map<int, bool> kMessageTypeDeletable = <int, bool>{
  0: true, // default
  1: true, // reply
  6: true, // channel pinned message
  7: true, // user join
  8: false, // recipient add
  9: false, // recipient remove
  10: false, // call
  11: false, // channel name change
  12: false, // channel icon change
  19: false, // client system
};

bool isMessageTypeDeletable(int type) {
  return kMessageTypeDeletable[type] ?? false;
}

bool canDeleteMessage({
  required Message message,
  required String? currentUserId,
  required bool isDmChannel,
  int? guildPermissionBits,
}) {
  if (message.hasFailed) {
    return true;
  }
  if (!isMessageTypeDeletable(message.type)) {
    return false;
  }
  if (currentUserId == null) {
    return false;
  }
  if (message.authorId == currentUserId) {
    return true;
  }
  if (isDmChannel) {
    return false;
  }
  if (guildPermissionBits == null) {
    return false;
  }
  return hasPermission(guildPermissionBits, Permission.manageMessages);
}
