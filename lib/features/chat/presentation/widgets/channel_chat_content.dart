import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel_header.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/channel_textarea.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/message_list.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';

/// Composite chat view that assembles the top bar, message list,
/// and input field. Works for both server channels and DMs.
class ChannelChatContent extends ConsumerStatefulWidget {
  final String channelId;
  final bool showTopBar;
  final String? targetMessageId;

  const ChannelChatContent({
    required this.channelId,
    this.showTopBar = true,
    this.targetMessageId,
    super.key,
  });

  @override
  ConsumerState<ChannelChatContent> createState() => _ChannelChatContentState();
}

class _ChannelChatContentState extends ConsumerState<ChannelChatContent> {
  @override
  void initState() {
    super.initState();
    unawaited(Future(_switchChannel));
  }

  @override
  void didUpdateWidget(ChannelChatContent oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.channelId != widget.channelId ||
        oldWidget.targetMessageId != widget.targetMessageId) {
      unawaited(Future(_switchChannel));
    }
  }

  Future<void> _switchChannel() => ref
      .read(chatViewModelProvider.notifier)
      .switchChannel(widget.channelId, targetMessageId: widget.targetMessageId);

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: context.colors.chatBackground,
      child: SafeArea(
        child: Column(
          children: [
            if (widget.showTopBar) const ChannelHeader(),
            Expanded(
              child: MessageList(targetMessageId: widget.targetMessageId),
            ),
            const ChannelTextarea(),
          ],
        ),
      ),
    );
  }
}
