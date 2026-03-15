import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/presentation/widgets/chat_top_bar.dart';
import 'package:fluxeron/features/chat/presentation/widgets/message_input.dart';
import 'package:fluxeron/features/chat/presentation/widgets/message_list.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';

/// Composite chat view that assembles the top bar, message list,
/// and input field. Works for both server channels and DMs.
class ChatView extends ConsumerStatefulWidget {
  final String channelId;
  final bool showTopBar;

  const ChatView({
    required this.channelId,
    this.showTopBar = true,
    super.key,
  });

  @override
  ConsumerState<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends ConsumerState<ChatView> {
  @override
  void initState() {
    super.initState();
    unawaited(Future(_switchChannel));
  }

  @override
  void didUpdateWidget(ChatView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId) {
      unawaited(Future(_switchChannel));
    }
  }

  Future<void> _switchChannel() =>
      ref.read(chatViewModelProvider.notifier).switchChannel(widget.channelId);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.chatBackground,
      child: SafeArea(
        child: Column(
          children: [
            if (widget.showTopBar) const ChatTopBar(),
            const Expanded(child: MessageList()),
            const MessageInput(),
          ],
        ),
      ),
    );
  }
}
