import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/chat/presentation/widgets/reply_preview.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';

/// The chat input bar at the bottom of the chat area.
class MessageInput extends ConsumerStatefulWidget {
  const MessageInput({super.key});

  @override
  ConsumerState<MessageInput> createState() => _MessageInputState();
}

class _MessageInputState extends ConsumerState<MessageInput> {
  final _controller = TextEditingController();

  @override
  void initState() {
    super.initState();
    _controller.addListener(() {
      ref
          .read(chatViewModelProvider.notifier)
          .updateMessageText(_controller.text);
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<String>(
      chatViewModelProvider.select((state) => state.messageText),
      (_, messageText) {
        if (_controller.text == messageText) {
          return;
        }
        _controller.value = TextEditingValue(
          text: messageText,
          selection: TextSelection.collapsed(offset: messageText.length),
        );
      },
    );

    final vm = ref.watch(chatViewModelProvider);
    final chatNotifier = ref.read(chatViewModelProvider.notifier);
    final replyTo = vm.replyingTo;
    final forwardFrom = vm.forwardingFrom;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (replyTo != null)
          ReplyInputBar(replyTo: replyTo, onCancel: chatNotifier.cancelReply),
        if (forwardFrom != null)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: FluxerColors.chatInputBackground,
            child: Row(
              children: [
                const PhosphorIcon(
                  PhosphorIconsFill.shareFat,
                  size: 16,
                  color: FluxerColors.textMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Forwarding message from '
                    '${forwardFrom.authorName}',
                    style: const TextStyle(
                      color: FluxerColors.textMuted,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.x, size: 16),
                  color: FluxerColors.textMuted,
                  onPressed: chatNotifier.cancelForward,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(
                    minWidth: 24,
                    minHeight: 24,
                  ),
                ),
              ],
            ),
          ),
        Container(
          height: 60,
          decoration: const BoxDecoration(
            color: FluxerColors.chatInputBackground,
            border: Border(top: BorderSide(color: FluxerColors.separator)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Row(
            children: [
              IconButton(
                icon: const PhosphorIcon(
                  PhosphorIconsFill.plusCircle,
                  size: 26,
                ),
                color: FluxerColors.interactiveNormal,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 40, minHeight: 40),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: TextField(
                  controller: _controller,
                  style: FluxerTextStyles.inputText,
                  onSubmitted: (_) => chatNotifier.sendMessage(),
                  decoration: const InputDecoration(
                    hintText: 'Message',
                    hintStyle: TextStyle(
                      color: FluxerColors.textFaint,
                      fontSize: 16,
                    ),
                    border: InputBorder.none,
                    isCollapsed: true,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.gift, size: 24),
                color: FluxerColors.interactiveNormal,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.gif, size: 24),
                color: FluxerColors.interactiveNormal,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.image, size: 24),
                color: FluxerColors.interactiveNormal,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.sticker, size: 24),
                color: FluxerColors.interactiveNormal,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const PhosphorIcon(PhosphorIconsFill.smiley, size: 24),
                color: FluxerColors.interactiveNormal,
                onPressed: () {},
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              const SizedBox(
                height: 24,
                child: VerticalDivider(
                  color: FluxerColors.divider,
                  width: 16,
                  thickness: 1,
                ),
              ),
              IconButton(
                icon: const PhosphorIcon(
                  PhosphorIconsFill.paperPlane,
                  size: 24,
                ),
                color: FluxerColors.blurple,
                onPressed: chatNotifier.sendMessage,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
