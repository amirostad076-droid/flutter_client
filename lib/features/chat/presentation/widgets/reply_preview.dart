import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_item.dart'
    show MessageItem;
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The inline reply indicator shown above a message that
/// is a reply. Displays a compact row with a truncated
/// reference to the replied-to message.
///
/// Since the full replied-to message is not available
/// inline (only the ID), this shows a generic indicator.
/// The curved connector line is handled by
/// [ReplyConnectorPainter] in [MessageItem].
class InlineReplyPreview extends StatelessWidget {
  final String replyToId;
  final VoidCallback? onTap;

  const InlineReplyPreview({required this.replyToId, this.onTap, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Row(
        children: [
          PhosphorIcon(
            PhosphorIconsFill.arrowBendUpLeft,
            size: 12,
            color: context.colors.textPrimaryMuted,
          ),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              'Reply to message',
              style: TextStyle(
                color: context.colors.textPrimaryMuted,
                fontSize: 12,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Paints the curved "L" connector line from the
/// replier's avatar area upward and across to the
/// reply preview row.
///
/// The line goes:
///   1. Up from just above the replier's avatar center
///   2. Curves right with a rounded corner
///   3. Extends horizontally to meet the reply
///      preview row
///
/// [avatarCenterX] -- x offset of the replier avatar
///   center (from left of widget)
/// [lineTop]       -- y offset where the horizontal arm
///   meets the reply row
/// [lineBottom]    -- y offset where the vertical arm
///   starts (just above avatar)
/// [horizontalEnd] -- x offset where the horizontal arm
///   ends (start of reply content)
class ReplyConnectorPainter extends CustomPainter {
  final double avatarCenterX;
  final double lineTop;
  final double lineBottom;
  final double horizontalEnd;
  final Color color;

  ReplyConnectorPainter({
    required this.avatarCenterX,
    required this.lineTop,
    required this.lineBottom,
    required this.horizontalEnd,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    const radius = 6.0;

    final path = Path()
      ..moveTo(avatarCenterX, lineBottom)
      ..lineTo(avatarCenterX, lineTop + radius)
      ..arcToPoint(
        Offset(avatarCenterX + radius, lineTop),
        radius: const Radius.circular(radius),
      )
      ..lineTo(horizontalEnd, lineTop);

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant ReplyConnectorPainter oldDelegate) =>
      avatarCenterX != oldDelegate.avatarCenterX ||
      lineTop != oldDelegate.lineTop ||
      lineBottom != oldDelegate.lineBottom ||
      horizontalEnd != oldDelegate.horizontalEnd ||
      color != oldDelegate.color;
}

/// The reply bar shown above the input when the user
/// is composing a reply.
class ReplyInputBar extends StatelessWidget {
  final Message replyTo;
  final VoidCallback onCancel;

  const ReplyInputBar({
    required this.replyTo,
    required this.onCancel,
    super.key,
  });

  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    color: context.colors.chatInputBackground,
    child: Row(
      children: [
        PhosphorIcon(
          PhosphorIconsFill.arrowBendUpLeft,
          size: 16,
          color: context.colors.textPrimaryMuted,
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            overflow: TextOverflow.ellipsis,
            text: TextSpan(
              style: const TextStyle(fontSize: 14),
              children: [
                TextSpan(
                  text: 'Replying to ',
                  style: TextStyle(color: context.colors.textPrimaryMuted),
                ),
                TextSpan(
                  text: replyTo.authorName,
                  style: TextStyle(
                    color: context.colors.textChat,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        IconButton(
          icon: const PhosphorIcon(PhosphorIconsFill.x, size: 16),
          color: context.colors.textPrimaryMuted,
          onPressed: onCancel,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
        ),
      ],
    ),
  );
}
