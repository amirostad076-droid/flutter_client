import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/route_names.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/domain/channel.dart';
import 'package:fluxeron/features/channels/presentation/widgets/channel_icon.dart';
import 'package:fluxeron/features/channels/providers/channel_providers.dart';
import 'package:fluxeron/features/guilds/providers/role_providers.dart';
import 'package:go_router/go_router.dart';

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
    final name = channel?.name ?? channelId;
    final type = channel?.type ?? ChannelType.text;

    return GestureDetector(
      onTap: channel == null
          ? null
          : () => context.go(
              RoutePaths.guildChannel(channel.serverId, channel.id),
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
  const _MentionPill({required this.child, this.color});

  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: color ?? colors.markupMentionFill,
        borderRadius: BorderRadius.circular(3),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
      child: child,
    );
  }
}


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
      color: fillColor,
      child: Text('@${role?.name ?? roleId}', style: style),
    );
  }
}
