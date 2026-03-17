import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxeron/features/chat/presentation/widgets/reply_preview.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';
import 'package:fluxeron/features/dm/providers/dm_view_model.dart';
import 'package:fluxeron/shared/utils/chat_context_utils.dart';
import 'package:fluxeron/shared/widgets/circle_icon_button.dart';
import 'package:fluxeron/shared/widgets/fade_icon_button.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// The chat input bar at the bottom of the chat area.
class ChannelTextarea extends ConsumerStatefulWidget {
  const ChannelTextarea({super.key});

  @override
  ConsumerState<ChannelTextarea> createState() => _ChannelTextareaState();
}

class _ChannelTextareaState extends ConsumerState<ChannelTextarea> {
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
            color: context.colors.chatInputBackground,
            child: Row(
              children: [
                PhosphorIcon(
                  PhosphorIconsFill.shareFat,
                  size: 16,
                  color: context.colors.textPrimaryMuted,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Forwarding message from '
                    '${forwardFrom.authorName}',
                    style: TextStyle(
                      color: context.colors.textPrimaryMuted,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const PhosphorIcon(PhosphorIconsFill.x, size: 16),
                  color: context.colors.textPrimaryMuted,
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
          decoration: BoxDecoration(
            color: context.colors.chatInputBackground,
            border: Border(top: BorderSide(color: context.colors.borderColor)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: ResponsiveLayout(
            builder: (context, mode) {
              switch (mode) {
                case LayoutMode.desktop:
                  return _buildLargeLayout(context, chatNotifier);
                case LayoutMode.tablet:
                  return _buildLargeLayout(context, chatNotifier);
                case LayoutMode.mobile:
                  return _buildMobileLayout(context, chatNotifier);
              }
            },
          ),
        ),
        Container(
          height: MediaQuery.of(context).padding.bottom,
          decoration: BoxDecoration(color: context.colors.chatInputBackground),
        ),
      ],
    );
  }

  String _resolveHintText() {
    final channelId = ref.read(
      chatViewModelProvider.select((s) => s.channelId),
    );
    final channelState = ref.read(channelListViewModelProvider);
    final channel = findChannelById(channelState, channelId);
    if (channel != null) {
      return 'Message #${channel.name}';
    }
    final conversations = ref.read(
      dmViewModelProvider.select((s) => s.conversations),
    );
    final dm = findDmById(conversations, channelId);
    if (dm != null) {
      return 'Message @${dm.recipientName}';
    }
    return 'Message';
  }

  Widget _buildLargeLayout(BuildContext context, ChatViewModel chatNotifier) {
    final hasText = ref.watch(
      chatViewModelProvider.select((s) => s.messageText.isNotEmpty),
    );
    return Row(
      children: [
        CircleIconButton(
          icon: PhosphorIconsFill.plusCircle,
          backgroundColor: context.colors.backgroundTertiary,
          iconColor: context.colors.interactiveNormal,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            style: context.textStyles.inputText,
            minLines: 1,
            maxLines: 5,
            decoration: InputDecoration(
              hintText: _resolveHintText(),
              hintStyle: TextStyle(
                color: context.colors.textTertiaryMuted,
                fontSize: 16,
              ),
              filled: true,
              fillColor: context.colors.backgroundTertiary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        const SizedBox(width: 4),
        if (!hasText) ...[
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.gift, size: 24),
            color: context.colors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.gif, size: 24),
            color: context.colors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.image, size: 24),
            color: context.colors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.sticker, size: 24),
            color: context.colors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
          IconButton(
            icon: const PhosphorIcon(PhosphorIconsFill.smiley, size: 24),
            color: context.colors.interactiveNormal,
            onPressed: () {},
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
          ),
        ],
        SizedBox(
          height: 24,
          child: VerticalDivider(
            color: context.colors.borderColor,
            width: 16,
            thickness: 1,
          ),
        ),
        _sendAndVoiceButton(context, chatNotifier, hasText: hasText),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context, ChatViewModel chatNotifier) {
    final hasText = ref.watch(
      chatViewModelProvider.select((s) => s.messageText.isNotEmpty),
    );

    return Row(
      children: [
        CircleIconButton(
          icon: Icons.add_rounded,
          backgroundColor: context.colors.backgroundTertiary,
          iconColor: context.colors.interactiveNormal,
          onTap: () {},
        ),
        const SizedBox(width: 8),
        Expanded(
          child: TextField(
            controller: _controller,
            style: context.textStyles.inputText,
            minLines: 1,
            maxLines: 6,
            decoration: InputDecoration(
              hintText: _resolveHintText(),
              hintStyle: TextStyle(
                color: context.colors.textTertiaryMuted,
                fontSize: 16,
              ),
              filled: true,
              fillColor: context.colors.backgroundTertiary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 8,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(24),
                borderSide: BorderSide.none,
              ),
              isDense: true,
              suffixIcon: FadeIconButton(
                icon: PhosphorIconsFill.smiley,
                iconColor: context.colors.textTertiaryMuted,
                onTap: () {},
                padding: const EdgeInsets.symmetric(vertical: 4, horizontal: 7),
              ),
              suffixIconConstraints: const BoxConstraints(),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsetsGeometry.only(bottom: 1),
          child: _sendAndVoiceButton(context, chatNotifier, hasText: hasText),
        ),
      ],
    );
  }

  Widget _sendAndVoiceButton(
    BuildContext context,
    ChatViewModel chatNotifier, {
    required bool hasText,
  }) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      transitionBuilder: (child, animation) =>
          FadeTransition(opacity: animation, child: child),
      child: hasText
          ? CircleIconButton(
              key: const ValueKey('send'),
              icon: Icons.arrow_upward_rounded,
              backgroundColor: context.colors.brandPrimary,
              iconColor: context.colors.textOnBrandPrimary,
              onTap: chatNotifier.sendMessage,
            )
          : CircleIconButton(
              key: const ValueKey('voice'),
              icon: PhosphorIconsFill.microphone,
              backgroundColor: context.colors.backgroundTertiary,
              iconColor: context.colors.interactiveNormal,
              onTap: () {},
            ),
    );
  }
}
