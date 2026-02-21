import 'package:flutter/material.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/features/chat/presentation/widgets/embed_image.dart';
import 'package:fluxeron/features/chat/presentation/widgets/embed_link.dart';
import 'package:fluxeron/features/chat/presentation/widgets/embed_rich.dart';
import 'package:fluxeron/features/chat/presentation/widgets/embed_video.dart';
import 'package:fluxeron/features/chat/presentation/'
    'widgets/forward_indicator.dart';
import 'package:fluxeron/features/chat/presentation/widgets/reply_preview.dart';
import 'package:fluxeron/shared/widgets/user_avatar.dart';

/// Avatar column width: 40px avatar + 16px gap to the
/// right.
const _kAvatarColumnWidth = 56.0;

/// Height of the compact reply-preview row.
const _kReplyRowHeight = 20.0;

/// Gap between the reply-preview row and the main message
/// row (avatar).
const _kReplyBottomGap = 4.0;

/// Horizontal gap between the end of the connector line
/// and the reply content.
const _kReplyLineEndGap = 6.0;

/// A single message row -- avatar, username, timestamp,
/// content, embeds, reactions, and action buttons on hover.
///
/// When the message is a reply, a compact preview of the
/// replied-to message is rendered above, with a curved
/// connector line from the replier's avatar to the reply
/// preview (matching Discord's layout).
class MessageBubble extends StatefulWidget {
  final Message message;
  final VoidCallback? onReply;
  final VoidCallback? onForward;

  const MessageBubble({
    required this.message,
    this.onReply,
    this.onForward,
    super.key,
  });

  @override
  State<MessageBubble> createState() => _MessageBubbleState();
}

class _MessageBubbleState extends State<MessageBubble> {
  var _isHovered = false;

  @override
  Widget build(BuildContext context) {
    final msg = widget.message;

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: Container(
        color: msg.isMentioned
            ? FluxerColors.mentionBackground
            : _isHovered
            ? FluxerColors.messageHover
            : Colors.transparent,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (msg.isReply) _buildReplyRow(msg),
                if (msg.isForwarded)
                  Padding(
                    padding: const EdgeInsets.only(left: _kAvatarColumnWidth),
                    child: ForwardIndicator(source: msg.forwardedFrom!),
                  ),
                _buildMainRow(msg),
              ],
            ),
            if (_isHovered)
              Positioned(top: 0, right: 0, child: _buildActions()),
          ],
        ),
      ),
    );
  }

  /// Builds the reply preview row with space for the
  /// connector line.
  Widget _buildReplyRow(Message msg) {
    const replyAreaHeight = _kReplyRowHeight + _kReplyBottomGap;
    const avatarCenterX = 20.0;
    const lineTop = _kReplyRowHeight / 2;
    const lineBottom = replyAreaHeight - 5;
    const horizontalEnd = _kAvatarColumnWidth - 5;
    const replyContentLeft = horizontalEnd + _kReplyLineEndGap;

    return SizedBox(
      height: replyAreaHeight,
      child: CustomPaint(
        painter: ReplyConnectorPainter(
          avatarCenterX: avatarCenterX,
          lineTop: lineTop,
          lineBottom: lineBottom,
          horizontalEnd: horizontalEnd,
        ),
        child: Padding(
          padding: const EdgeInsets.only(
            left: replyContentLeft,
            bottom: _kReplyBottomGap,
          ),
          child: SizedBox(
            height: _kReplyRowHeight,
            child: Align(
              alignment: Alignment.centerLeft,
              child: InlineReplyPreview(replyToId: msg.replyToId!),
            ),
          ),
        ),
      ),
    );
  }

  /// Main message row: avatar on the left, content on
  /// the right.
  Widget _buildMainRow(Message msg) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Padding(
        padding: const EdgeInsets.only(top: 2),
        child: UserAvatar(
          displayName: msg.authorName,
          avatarUrl: msg.authorAvatarUrl,
          avatarColor: msg.authorAvatarColor,
        ),
      ),
      const SizedBox(width: 16),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  msg.authorName,
                  style: const TextStyle(
                    color: FluxerColors.textNormal,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  _formatTimestamp(msg.timestamp),
                  style: FluxerTextStyles.timestamp,
                ),
                if (msg.isEdited) ...[
                  const SizedBox(width: 4),
                  const Text(
                    '(edited)',
                    style: TextStyle(
                      color: FluxerColors.textFaint,
                      fontSize: 10,
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 2),
            if (msg.content.isNotEmpty)
              SelectableText(msg.content, style: FluxerTextStyles.messageText),
            ...msg.embeds.map(_buildEmbed),
            if (msg.reactions.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: msg.reactions.map(_buildReaction).toList(),
                ),
              ),
          ],
        ),
      ),
    ],
  );

  Widget _buildEmbed(Embed embed) => Padding(
    padding: const EdgeInsets.only(top: 2),
    child: switch (embed.type) {
      EmbedType.rich => EmbedRich(embed: embed),
      EmbedType.image => EmbedImage(embed: embed),
      EmbedType.link => EmbedLink(embed: embed),
      EmbedType.video => EmbedVideo(embed: embed),
    },
  );

  Widget _buildReaction(Reaction reaction) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
    decoration: BoxDecoration(
      color: reaction.hasReacted
          ? FluxerColors.blurple.withValues(alpha: 0.3)
          : FluxerColors.backgroundAccent.withValues(alpha: 0.4),
      border: Border.all(
        color: reaction.hasReacted ? FluxerColors.blurple : Colors.transparent,
      ),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(reaction.emoji, style: const TextStyle(fontSize: 16)),
        const SizedBox(width: 4),
        Text(
          '${reaction.count}',
          style: TextStyle(
            color: reaction.hasReacted
                ? FluxerColors.blurple
                : FluxerColors.textNormal,
            fontSize: 12,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    ),
  );

  Widget _buildActions() => Material(
    color: FluxerColors.backgroundPrimary,
    borderRadius: BorderRadius.circular(4),
    child: DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: FluxerColors.divider),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _actionButton(PhosphorIconsFill.smiley, 'Add Reaction', () {}),
          _actionButton(
            PhosphorIconsFill.arrowBendUpLeft,
            'Reply',
            widget.onReply,
          ),
          _actionButton(
            PhosphorIconsFill.shareFat,
            'Forward',
            widget.onForward,
          ),
          _actionButton(PhosphorIconsFill.dotsThree, 'More', () {}),
        ],
      ),
    ),
  );

  Widget _actionButton(IconData icon, String tooltip, VoidCallback? onTap) =>
      Tooltip(
        message: tooltip,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: PhosphorIcon(
              icon,
              size: 18,
              color: FluxerColors.interactiveNormal,
            ),
          ),
        ),
      );

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final isToday =
        dt.year == now.year && dt.month == now.month && dt.day == now.day;
    final h = dt.hour.toString().padLeft(2, '0');
    final m = dt.minute.toString().padLeft(2, '0');
    if (isToday) {
      return 'Today at $h:$m';
    }
    return '${dt.month}/${dt.day}/${dt.year} $h:$m';
  }
}
