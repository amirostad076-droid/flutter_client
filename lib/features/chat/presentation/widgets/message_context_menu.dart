import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/features/chat/presentation/widgets/message_action_sheet.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

Future<MessageAction?> showMessageContextMenu(
  BuildContext context, {
  required Offset position,
  required Message message,
  required bool isOwnMessage,
}) async {
  final overlay =
      Overlay.of(context).context.findRenderObject()
          as RenderBox?;
  if (overlay == null) {
    return null;
  }

  final items = <PopupMenuEntry<MessageAction>>[
    _buildItem(
      context,
      icon: PhosphorIconsFill.arrowBendUpLeft,
      label: 'Reply',
      value: MessageAction.reply,
    ),
    _buildItem(
      context,
      icon: PhosphorIconsFill.shareFat,
      label: 'Forward',
      value: MessageAction.forward,
    ),
    if (message.content.isNotEmpty)
      _buildItem(
        context,
        icon: PhosphorIconsFill.copy,
        label: 'Copy Text',
        value: MessageAction.copyText,
      ),
    _buildItem(
      context,
      icon: PhosphorIconsFill.smiley,
      label: 'Add Reaction',
      value: MessageAction.addReaction,
    ),
    const PopupMenuDivider(),
    _buildItem(
      context,
      icon: PhosphorIconsFill.pushPin,
      label: message.isPinned ? 'Unpin' : 'Pin',
      value: MessageAction.pin,
    ),
    if (isOwnMessage) ...[
      const PopupMenuDivider(),
      _buildItem(
        context,
        icon: PhosphorIconsFill.pencil,
        label: 'Edit',
        value: MessageAction.edit,
      ),
      _buildItem(
        context,
        icon: PhosphorIconsFill.trash,
        label: 'Delete',
        value: MessageAction.delete,
        isDanger: true,
      ),
    ],
  ];

  final action = await showMenu<MessageAction>(
    context: context,
    position: RelativeRect.fromLTRB(
      position.dx,
      position.dy,
      overlay.size.width - position.dx,
      overlay.size.height - position.dy,
    ),
    color: context.colors.backgroundFloating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    items: items,
  );

  if (action == MessageAction.copyText) {
    await Clipboard.setData(
      ClipboardData(text: message.content),
    );
  }

  return action;
}

PopupMenuItem<MessageAction> _buildItem(
  BuildContext context, {
  required IconData icon,
  required String label,
  required MessageAction value,
  bool isDanger = false,
}) {
  final color = isDanger
      ? context.colors.textDanger
      : context.colors.textChat;

  return PopupMenuItem<MessageAction>(
    value: value,
    height: 36,
    child: Row(
      children: [
        PhosphorIcon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: color, fontSize: 14),
        ),
      ],
    ),
  );
}
