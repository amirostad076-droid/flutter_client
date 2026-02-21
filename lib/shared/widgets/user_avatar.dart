import 'package:flutter/material.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/features/servers/domain/server.dart';

class UserAvatar extends StatelessWidget {
  final String displayName;
  final String? avatarUrl;
  final int? avatarColor;
  final int? roleColor;
  final String status;
  final double size;
  final bool showStatus;

  const UserAvatar({
    required this.displayName,
    this.avatarUrl,
    this.avatarColor,
    this.roleColor,
    this.status = 'offline',
    this.size = 40,
    this.showStatus = true,
    super.key,
  });

  factory UserAvatar.fromRow(
    db.User user, {
    double size = 40,
    bool showStatus = true,
  }) {
    final avatar = user.avatar;
    String? url;
    if (avatar != null) {
      url = '$fluxerMediaCdn/avatars/${user.id}/$avatar.png';
    }
    return UserAvatar(
      displayName: user.globalName ?? user.username,
      avatarUrl: url,
      avatarColor: user.avatarColor,
      status: user.status,
      size: size,
      showStatus: showStatus,
    );
  }

  @override
  Widget build(BuildContext context) => SizedBox(
    width: size,
    height: size,
    child: Stack(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: _backgroundColor,
          backgroundImage: avatarUrl != null ? NetworkImage(avatarUrl!) : null,
          child: avatarUrl == null
              ? Text(
                  displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: FluxerColors.white,
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.w600,
                  ),
                )
              : null,
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: _statusColor,
                shape: BoxShape.circle,
                border: Border.all(
                  color: FluxerColors.backgroundPrimary,
                  width: size * 0.06,
                ),
              ),
              child: status == 'dnd'
                  ? Center(
                      child: Container(
                        width: size * 0.12,
                        height: size * 0.04,
                        decoration: BoxDecoration(
                          color: FluxerColors.backgroundPrimary,
                          borderRadius: BorderRadius.circular(1),
                        ),
                      ),
                    )
                  : status == 'idle'
                  ? ClipOval(
                      child: Align(
                        alignment: const Alignment(0.4, -0.4),
                        child: Container(
                          width: size * 0.16,
                          height: size * 0.16,
                          decoration: const BoxDecoration(
                            color: FluxerColors.backgroundPrimary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    )
                  : null,
            ),
          ),
      ],
    ),
  );

  Color get _statusColor {
    switch (status) {
      case 'online':
        return FluxerColors.online;
      case 'idle':
        return FluxerColors.idle;
      case 'dnd':
        return FluxerColors.dnd;
      case 'streaming':
        return FluxerColors.streaming;
      default:
        return FluxerColors.offline;
    }
  }

  Color get _backgroundColor {
    if (roleColor != null) {
      return Color(roleColor!);
    }
    if (avatarColor != null) {
      return Color(avatarColor!);
    }
    final hash = displayName.hashCode;
    const colors = [
      Color(0xFF5865F2),
      Color(0xFF57F287),
      Color(0xFFFEE75C),
      Color(0xFFEB459E),
      Color(0xFFED4245),
    ];
    return colors[hash.abs() % colors.length];
  }
}
