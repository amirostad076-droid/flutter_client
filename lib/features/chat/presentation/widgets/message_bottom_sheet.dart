import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

enum MessageAction {
  addReaction,
  edit,
  reply,
  forward,
  copyText,
  pin,
  bookmark,
  markAsUnread,
  copyMessageLink,
  delete,
  copyMessageId,
}

Future<MessageAction?> showMessageBottomSheet(
  BuildContext context, {
  required Message message,
  required bool isOwnMessage,
}) => showModalBottomSheet<MessageAction>(
  context: context,
  backgroundColor: context.colors.backgroundSecondary,
  shape: const RoundedRectangleBorder(
    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
  ),
  builder: (_) =>
      MessageBottomSheet(message: message, isOwnMessage: isOwnMessage),
);

class MessageBottomSheet extends StatelessWidget {
  final Message message;
  final bool isOwnMessage;

  const MessageBottomSheet({
    required this.message,
    required this.isOwnMessage,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Center(
            child: Container(
              width: 32,
              height: 4,
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: context.colors.textTertiaryMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          _ActionRow(
            icon: PhosphorIconsRegular.smiley,
            label: 'Add Reaction',
            onTap: () => Navigator.pop(context, MessageAction.addReaction),
          ),
          if (isOwnMessage)
            _ActionRow(
              icon: PhosphorIconsRegular.pencilSimple,
              label: 'Edit Message',
              onTap: () => Navigator.pop(context, MessageAction.edit),
            ),
          _ActionRow(
            icon: PhosphorIconsRegular.arrowBendUpLeft,
            label: 'Reply',
            onTap: () => Navigator.pop(context, MessageAction.reply),
          ),
          _ActionRow(
            icon: PhosphorIconsRegular.shareFat,
            label: 'Forward',
            onTap: () => Navigator.pop(context, MessageAction.forward),
          ),
          if (message.content.isNotEmpty)
            _ActionRow(
              icon: PhosphorIconsRegular.copy,
              label: 'Copy Text',
              onTap: () async {
                await Clipboard.setData(ClipboardData(text: message.content));
                if (!context.mounted) {
                  return;
                }
                Navigator.pop(context, MessageAction.copyText);
              },
            ),
          _ActionRow(
            icon: PhosphorIconsRegular.pushPin,
            label: message.isPinned ? 'Unpin Message' : 'Pin Message',
            onTap: () => Navigator.pop(context, MessageAction.pin),
          ),
          _ActionRow(
            icon: PhosphorIconsRegular.bookmarkSimple,
            label: 'Bookmark Message',
            onTap: () => Navigator.pop(context, MessageAction.bookmark),
          ),
          _ActionRow(
            icon: PhosphorIconsRegular.envelopeSimple,
            label: 'Mark as Unread',
            onTap: () => Navigator.pop(context, MessageAction.markAsUnread),
          ),
          if (isOwnMessage)
            _ActionRow(
              icon: PhosphorIconsRegular.trash,
              label: 'Delete Message',
              color: context.colors.textDanger,
              onTap: () => Navigator.pop(context, MessageAction.delete),
            ),
        ],
      ),
    );
  }
}

class _ActionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  final VoidCallback onTap;

  const _ActionRow({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final rowColor = color ?? context.colors.textPrimary;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            PhosphorIcon(icon, size: 22, color: rowColor),
            const SizedBox(width: 16),
            Text(label, style: TextStyle(color: rowColor, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
