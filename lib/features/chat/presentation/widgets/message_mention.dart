import 'dart:async';

import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/utils/channel_jump_link.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxer_app/features/channels/providers/channel_providers.dart';
import 'package:fluxer_app/features/guilds/domain/guild.dart';
import 'package:fluxer_app/features/guilds/providers/role_providers.dart';
import 'package:fluxer_app/features/profile/presentation/user_profile_sheet.dart';
import 'package:fluxer_app/features/ui/button/fluxer_button.dart';
import 'package:fluxer_app/features/ui/modal/fluxer_modal.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:riverpod/src/providers/future_provider.dart';

class ChannelMention extends ConsumerWidget {
  const ChannelMention({required this.channelId, this.baseStyle, super.key});

  final String channelId;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(channelByIdProvider(channelId));
    final colors = context.colors;
    final style = (baseStyle ?? const TextStyle()).copyWith(
      color: colors.markupMentionText,
      fontWeight: FontWeight.w500,
    );

    final channel = async.value;
    final name =
        channel?.name ?? FluxerLocalizations.of(context).mentionUnknownChannel;
    final type = channel?.type ?? ChannelType.text;

    return GestureDetector(
      onTap: channel == null
          ? null
          : () => context.go(
              RoutePaths.guildChannel(channel.guildId, channel.id),
            ),
      child: _MentionPill(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ChannelIcon(
              type: type,
              size: (style.fontSize ?? 14) * 0.9,
              color: colors.markupMentionText,
            ),
            const SizedBox(width: 2),
            Text(name, style: style),
          ],
        ),
      ),
    );
  }
}

class TextMention extends StatelessWidget {
  const TextMention({required this.label, this.baseStyle, super.key});

  final String label;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = (baseStyle ?? const TextStyle()).copyWith(
      color: colors.markupMentionText,
      fontWeight: FontWeight.w500,
    );
    return _MentionPill(child: Text(label, style: style));
  }
}

class _MentionPill extends StatelessWidget {
  const _MentionPill({required this.child, this.fillColor});

  final Widget child;
  final Color? fillColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: fillColor ?? colors.markupMentionFill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: colors.markupMentionBorder),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3.2),
      child: child,
    );
  }
}

class UserMention extends ConsumerWidget {
  const UserMention({
    required this.userId,
    this.channelId,
    this.baseStyle,
    super.key,
  });

  final String userId;
  final String? channelId;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final guildId = ref.watch(activeGuildIdProvider);

    final userAsync = ref.watch(_userByIdProvider(userId));
    final memberAsync = guildId != null
        ? ref.watch(_memberByUserIdProvider((userId, guildId)))
        : null;

    final user = userAsync.value;
    final member = memberAsync?.value;

    final name = member?.nick ?? user?.globalName ?? user?.username ?? userId;

    final colors = context.colors;
    final style = (baseStyle ?? const TextStyle()).copyWith(
      color: colors.markupMentionText,
      fontWeight: FontWeight.w500,
    );
    return GestureDetector(
      onTap: () => unawaited(
        FluxerUserProfileSheet.show(context, userId: userId, guildId: guildId),
      ),
      child: _MentionPill(child: Text('@$name', style: style)),
    );
  }
}

final FutureProviderFamily<User?, String> _userByIdProvider = FutureProvider
    .autoDispose
    .family<User?, String>((ref, id) {
      final db = ref.watch(fluxerDatabaseProvider);
      return db.userDao.getUserById(id);
    });

final FutureProviderFamily<Member?, (String, String)> _memberByUserIdProvider =
    FutureProvider.autoDispose.family<Member?, (String, String)>((ref, args) {
      final (userId, guildId) = args;
      final db = ref.watch(fluxerDatabaseProvider);
      return db.memberDao.getMemberByUserId(userId, guildId);
    });

class RoleMention extends ConsumerWidget {
  const RoleMention({required this.roleId, this.baseStyle, super.key});

  final String roleId;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(roleByIdProvider(roleId));
    final colors = context.colors;
    final role = async.value;

    final hasColor = (role?.color ?? 0) != 0;
    final roleColor = hasColor ? Color(role!.color | 0xFF000000) : null;
    // 0.1 opacity fill matching web app
    final fillColor = roleColor?.withValues(alpha: 0.1);

    final style = (baseStyle ?? const TextStyle()).copyWith(
      color: roleColor ?? colors.markupMentionText,
      fontWeight: FontWeight.w500,
    );

    return _MentionPill(
      fillColor: fillColor,
      child: Text('@${role?.name ?? roleId}', style: style),
    );
  }
}

final FutureProviderFamily<Guild?, String> _guildByIdProvider = FutureProvider
    .autoDispose
    .family<Guild?, String>((ref, id) async {
      final db = ref.watch(fluxerDatabaseProvider);
      final row = await db.guildDao.getServerById(id);
      return row == null ? null : Guild.fromRow(row);
    });

// temporary solution :)
final FutureProviderFamily<String?, String> _dmNameByChannelIdProvider =
    FutureProvider.autoDispose.family<String?, String>((ref, channelId) async {
      final db = ref.watch(fluxerDatabaseProvider);
      final row = await db.dmChannelDao.getDmChannelById(channelId);
      if (row == null) {
        return null;
      }
      final user = await db.userDao.getUserById(row.recipientId);
      if (row.type == 3) {
        return row.name ?? 'Group DM';
      }
      return user?.globalName ?? user?.username;
    });

class ChannelJumpLinkMention extends ConsumerWidget {
  const ChannelJumpLinkMention({
    required this.link,
    required this.url,
    this.baseStyle,
    super.key,
  });

  final ChannelJumpLink link;
  final String url;
  final TextStyle? baseStyle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isMessage = link is MessageJumpLink;

    final channelAsync = link.isDm
        ? null
        : ref.watch(channelByIdProvider(link.channelId));
    final guildAsync = link.isDm
        ? null
        : ref.watch(_guildByIdProvider(link.scope));
    final dmNameAsync = link.isDm
        ? ref.watch(_dmNameByChannelIdProvider(link.channelId))
        : null;

    final channel = channelAsync?.value;
    final guild = guildAsync?.value;
    final dmName = dmNameAsync?.value ?? link.channelId;

    final colors = context.colors;
    final style = (baseStyle ?? const TextStyle()).copyWith(
      color: colors.markupMentionText,
      fontWeight: FontWeight.w500,
    );
    final iconSize = (style.fontSize ?? 14) * 0.9;

    void onTap() {
      // Channel not found
      if (!link.isDm && channel == null) {
        final l10n = FluxerLocalizations.of(context);
        unawaited(
          FluxerModal.show<void>(
            context,
            title: l10n.channelAccessDeniedTitle,
            builder: (ctx, close) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  l10n.channelAccessDeniedDescription,
                  style: ctx.textStyles.bodySmall.copyWith(height: 1.4),
                ),
                const SizedBox(height: 16),
                FluxerButton.primary(onPressed: close, label: l10n.okay),
              ],
            ),
          ),
        );
        return;
      }
      final router = ProviderScope.containerOf(
        context,
      ).read(fluxerRouterProvider);
      final messageId = isMessage ? (link as MessageJumpLink).messageId : null;
      if (link.isDm) {
        if (messageId != null) {
          router.go(RoutePaths.dmChannelMessage(link.channelId, messageId));
        } else {
          router.go(RoutePaths.dmChannel(link.channelId));
        }
      } else if (messageId != null) {
        router.go(
          RoutePaths.guildChannelMessage(link.scope, link.channelId, messageId),
        );
      } else {
        router.go(RoutePaths.guildChannel(link.scope, link.channelId));
      }
    }

    if (!link.isDm && channel == null && channelAsync?.isLoading == false) {
      return GestureDetector(
        onTap: onTap,
        child: Text(
          url,
          style: style.copyWith(
            color: colors.textLink,
            decoration: TextDecoration.none,
          ),
        ),
      );
    }

    return _JumpLinkPill(
      onTap: onTap,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (link.isDm) ...[
            if (isMessage)
              Text(dmName, style: style)
            else
              Text('# $dmName', style: style),
            if (isMessage) ...[
              Padding(
                padding: EdgeInsets.symmetric(horizontal: iconSize * 0.1),
                child: PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: iconSize * 0.6,
                  color: colors.markupMentionText,
                ),
              ),
              PhosphorIcon(
                PhosphorIconsFill.chatCircle,
                size: iconSize,
                color: colors.markupMentionText,
              ),
            ],
          ] else ...[
            if (guild != null) ...[
              _GuildIcon(guild: guild, size: iconSize),
              SizedBox(width: iconSize * 0.2),
              Text(guild.name, style: style),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: iconSize * 0.1),
                child: PhosphorIcon(
                  PhosphorIconsBold.caretRight,
                  size: iconSize * 0.6,
                  color: colors.markupMentionText,
                ),
              ),
            ],
            if (isMessage)
              PhosphorIcon(
                PhosphorIconsFill.chatCircle,
                size: iconSize,
                color: colors.markupMentionText,
              )
            else ...[
              ChannelIcon(
                type: channel?.type ?? ChannelType.text,
                size: iconSize,
                color: colors.markupMentionText,
              ),
              SizedBox(width: iconSize * 0.2),
              Text(channel?.name ?? link.channelId, style: style),
            ],
          ],
        ],
      ),
    );
  }
}

class _JumpLinkPill extends StatefulWidget {
  const _JumpLinkPill({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  State<_JumpLinkPill> createState() => _JumpLinkPillState();
}

class _JumpLinkPillState extends State<_JumpLinkPill> {
  var _hovered = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return MouseRegion(
      onEnter: (_) => setState(() => _hovered = true),
      onExit: (_) => setState(() => _hovered = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 50),
          decoration: BoxDecoration(
            color: _hovered
                ? colors.markupJumpLinkHoverFill
                : colors.markupJumpLinkFill,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: colors.markupMentionBorder),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 3.2),
          child: widget.child,
        ),
      ),
    );
  }
}

class _GuildIcon extends StatelessWidget {
  const _GuildIcon({required this.guild, required this.size});

  final Guild guild;
  final double size;

  @override
  Widget build(BuildContext context) {
    final url = guild.iconUrl;
    if (url != null) {
      return ClipOval(
        child: CachedNetworkImage(
          imageUrl: url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _GuildInitials(guild: guild, size: size),
        ),
      );
    }
    return _GuildInitials(guild: guild, size: size);
  }
}

class _GuildInitials extends StatelessWidget {
  const _GuildInitials({required this.guild, required this.size});

  final Guild guild;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = guild.name.isNotEmpty ? guild.name[0].toUpperCase() : '?';
    final colors = context.colors;
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: size * 0.6,
          fontWeight: FontWeight.w700,
          color: colors.markupMentionText,
          height: 1,
        ),
      ),
    );
  }
}
