import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';

import 'package:fluxeron/core/database/fluxer_database.dart' as db;
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/guilds/domain/guild.dart';
import 'package:fluxeron/features/ui/status_indicator/fluxer_status_indicator.dart';

const _kDefaultAvatarCount = 6;
const _kStaticCdnUrl = 'https://fluxerstatic.com';

const _kFallbackColors = [
  Color(0xFF5865F2),
  Color(0xFF57F287),
  Color(0xFFFEE75C),
  Color(0xFFEB459E),
  Color(0xFFED4245),
];

enum _AvatarShape { circle, rounded }

class FluxerAvatar extends StatelessWidget {
  const FluxerAvatar({
    this.imageUrl,
    this.fallbackText,
    this.size = 32,
    super.key,
  }) : _shape = _AvatarShape.circle,
       status = null,
       showStatus = false,
       avatarColor = null,
       roleColor = null,
       _userId = null;

  const FluxerAvatar.user({
    this.imageUrl,
    this.fallbackText,
    this.status,
    this.size = 40,
    this.showStatus = true,
    this.avatarColor,
    this.roleColor,
    String? userId,
    super.key,
  }) : _shape = _AvatarShape.circle,
       _userId = userId;

  const FluxerAvatar.guild({
    this.imageUrl,
    this.fallbackText,
    this.size = 44,
    super.key,
  }) : _shape = _AvatarShape.rounded,
       status = null,
       showStatus = false,
       avatarColor = null,
       roleColor = null,
       _userId = null;

  factory FluxerAvatar.fromUserRow(
    db.User user, {
    double size = 40,
    bool showStatus = true,
  }) {
    final avatar = user.avatar;
    String? url;
    if (avatar != null) {
      url = '$fluxerMediaCdn/avatars/${user.id}/$avatar.png';
    }
    return FluxerAvatar.user(
      imageUrl: url,
      fallbackText: user.globalName ?? user.username,
      status: user.status,
      size: size,
      showStatus: showStatus,
      avatarColor: user.avatarColor,
      userId: user.id,
    );
  }

  final String? imageUrl;
  final String? fallbackText;
  final double size;
  final String? status;
  final bool showStatus;
  final int? avatarColor;
  final int? roleColor;
  final _AvatarShape _shape;
  final String? _userId;

  String? get _resolvedImageUrl {
    if (imageUrl != null) {
      return imageUrl;
    }
    final userId = _userId;
    if (userId == null || userId.isEmpty) {
      return null;
    }
    final index = BigInt.parse(userId) % BigInt.from(_kDefaultAvatarCount);
    return '$_kStaticCdnUrl/avatars/$index.png';
  }

  Color get _backgroundColor {
    if (roleColor != null) {
      return Color(roleColor!);
    }
    if (avatarColor != null) {
      return Color(avatarColor!);
    }
    final text = fallbackText ?? '';
    return _kFallbackColors[text.hashCode.abs() % _kFallbackColors.length];
  }

  BorderRadius get _borderRadius => _shape == _AvatarShape.rounded
      ? BorderRadius.circular(size * 0.27)
      : BorderRadius.circular(size / 2);

  @override
  Widget build(BuildContext context) {
    final resolvedUrl = _resolvedImageUrl;
    final hasStatus = showStatus && status != null;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              color: _backgroundColor,
              borderRadius: _borderRadius,
            ),
            child: ClipRRect(
              borderRadius: _borderRadius,
              child: resolvedUrl != null
                  ? CachedNetworkImage(
                      imageUrl: resolvedUrl,
                      width: size,
                      height: size,
                      fit: BoxFit.cover,
                      errorBuilder: (_, _, _) => _buildFallback(context),
                    )
                  : _buildFallback(context),
            ),
          ),
          if (hasStatus)
            Positioned(
              right: 0,
              bottom: 0,
              child: FluxerStatusIndicator(status: status!, size: size * 0.3),
            ),
        ],
      ),
    );
  }

  Widget _buildFallback(BuildContext context) {
    final text = fallbackText;
    final initial = (text != null && text.isNotEmpty)
        ? text[0].toUpperCase()
        : '?';
    return Center(
      child: Text(
        initial,
        style: TextStyle(
          color: context.colors.textPrimary,
          fontSize: size * 0.4,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
