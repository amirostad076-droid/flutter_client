import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/friends/domain/friend.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class UserProfileRelationshipButton extends StatelessWidget {
  const UserProfileRelationshipButton({
    required this.relationshipStatus,
    required this.isCurrentUser,
    required this.onUnblock,
    required this.onRemoveFriend,
    required this.onAcceptRequest,
    required this.onCancelRequest,
    required this.onSendFriendRequest,
    super.key,
  });

  final FriendStatus? relationshipStatus;
  final bool isCurrentUser;
  final VoidCallback onUnblock;
  final VoidCallback onRemoveFriend;
  final VoidCallback onAcceptRequest;
  final VoidCallback onCancelRequest;
  final VoidCallback onSendFriendRequest;

  ({PhosphorIconData icon, VoidCallback onTap})? _resolve() {
    if (isCurrentUser) {
      return null;
    }
    final status = relationshipStatus;
    return switch (status) {
      FriendStatus.accepted => (
        icon: PhosphorIconsFill.userMinus,
        onTap: onRemoveFriend,
      ),
      FriendStatus.blocked => (
        icon: PhosphorIconsFill.prohibit,
        onTap: onUnblock,
      ),
      FriendStatus.pendingIncoming => (
        icon: PhosphorIconsFill.checkCircle,
        onTap: onAcceptRequest,
      ),
      FriendStatus.pendingOutgoing => (
        icon: PhosphorIconsFill.clockCounterClockwise,
        onTap: onCancelRequest,
      ),
      null => (
        icon: PhosphorIconsFill.userPlus,
        onTap: onSendFriendRequest,
      ),
    };
  }

  @override
  Widget build(BuildContext context) {
    final action = _resolve();
    if (action == null) {
      return const SizedBox.shrink();
    }

    final colors = context.colors;
    return FluxerTappable(
      onTap: action.onTap,
      builder: (context, _) => Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: colors.backgroundTertiary,
          shape: BoxShape.circle,
        ),
        alignment: Alignment.center,
        child: PhosphorIcon(action.icon, size: 20, color: colors.textPrimary),
      ),
    );
  }
}
