import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';

/// Default avatar index: id % 6, matching the default avatar set
const _kDefaultAvatarCount = 6;
const _kStaticCdnUrl = 'https://fluxerstatic.com';

class UserAvatar extends StatelessWidget {
  final String displayName;
  final String userId;
  final String? avatarUrl;
  final int? avatarColor;
  final int? roleColor;
  final String status;
  final double size;
  final bool showStatus;

  const UserAvatar({
    required this.displayName,
    required this.userId,
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
      userId: user.id,
      avatarUrl: url,
      avatarColor: user.avatarColor,
      status: user.status,
      size: size,
      showStatus: showStatus,
    );
  }

  String get _resolvedAvatarUrl {
    if (avatarUrl != null) {
      return avatarUrl!;
    }
    final index = userId.hashCode.abs() % _kDefaultAvatarCount;
    return '$_kStaticCdnUrl/avatars/$index.png';
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
          child: ClipOval(
            child: CachedNetworkImage(
              imageUrl: _resolvedAvatarUrl,
              width: size,
              height: size,
              fit: BoxFit.cover,
              errorBuilder: (context, url, error) => _buildInitial(context),
            ),
          ),
        ),
        if (showStatus)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.3,
              height: size * 0.3,
              decoration: BoxDecoration(
                color: _statusColor(context),
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.colors.backgroundPrimary,
                  width: size * 0.06,
                ),
              ),
              child: status == 'dnd'
                  ? Center(
                      child: Container(
                        width: size * 0.12,
                        height: size * 0.04,
                        decoration: BoxDecoration(
                          color: context.colors.backgroundPrimary,
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
                          decoration: BoxDecoration(
                            color: context.colors.backgroundPrimary,
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

  Widget _buildInitial(BuildContext context) => Text(
    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
    style: TextStyle(
      color: context.colors.textPrimary,
      fontSize: size * 0.4,
      fontWeight: FontWeight.w600,
    ),
  );

  Color _statusColor(BuildContext context) {
    switch (status) {
      case 'online':
        return context.colors.statusOnline;
      case 'idle':
        return context.colors.statusIdle;
      case 'dnd':
        return context.colors.statusDnd;
      case 'streaming':
        return context.colors.statusDanger;
      default:
        return context.colors.statusOffline;
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
