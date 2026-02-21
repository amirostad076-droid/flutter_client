import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:phosphor_flutter/phosphor_flutter.dart';

import 'package:fluxeron/core/theme/fluxer_colors.dart';
import 'package:fluxeron/core/theme/fluxer_text_styles.dart';
import 'package:fluxeron/features/chat/presentation/'
    'widgets/message_bubble.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';

const _kLoadMoreThreshold = 200.0;

/// The scrollable list of messages in the chat area.
///
/// Uses a reversed [ListView] so newest messages appear at the
/// bottom and scrolling up loads older messages.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key});

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController
      ..removeListener(_onScroll)
      ..dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_scrollController.hasClients) {
      return;
    }
    final pos = _scrollController.position;
    if (pos.pixels >= pos.maxScrollExtent - _kLoadMoreThreshold) {
      unawaited(ref.read(chatViewModelProvider.notifier).loadMore());
    }
  }

  void _onScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        unawaited(
          _scrollController.animateTo(
            0,
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeOut,
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      chatViewModelProvider.select((state) => state.scrollToBottomSignal),
      (previous, next) {
        if (next != previous) {
          _onScrollToBottom();
        }
      },
    );

    final state = ref.watch(chatViewModelProvider);
    final messages = state.messages;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(color: FluxerColors.blurple),
      );
    }

    if (messages.isEmpty) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.chatCircleDots,
              size: 48,
              color: FluxerColors.textMuted,
            ),
            SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(color: FluxerColors.textMuted, fontSize: 16),
            ),
            SizedBox(height: 4),
            Text(
              'Be the first to send a message!',
              style: TextStyle(color: FluxerColors.textFaint, fontSize: 14),
            ),
          ],
        ),
      );
    }

    // With reverse: true, index 0 is at the bottom (newest).
    // Messages in state are oldest-first, so we read them
    // from the end.
    final itemCount =
        messages.length +
        1 + // date separator at the top (oldest)
        (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(top: 8, bottom: 16),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // index 0 = newest message (bottom of screen)
        if (index < messages.length) {
          final msgIndex = messages.length - 1 - index;
          final msg = messages[msgIndex];
          return MessageBubble(
            message: msg,
            onReply: () =>
                ref.read(chatViewModelProvider.notifier).startReply(msg),
            onForward: () =>
                ref.read(chatViewModelProvider.notifier).startForward(msg),
          );
        }

        // Date separator above the oldest message
        if (index == messages.length) {
          return _buildDateSeparator(messages.first.timestamp);
        }

        // Loading indicator at the very top
        return const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: FluxerColors.blurple,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDateSeparator(DateTime date) {
    final months = [
      'January',
      'February',
      'March',
      'April',
      'May',
      'June',
      'July',
      'August',
      'September',
      'October',
      'November',
      'December',
    ];
    final formatted =
        '${months[date.month - 1]} ${date.day},'
        ' ${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          const Expanded(child: Divider(color: FluxerColors.divider)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(formatted, style: FluxerTextStyles.smallText),
          ),
          const Expanded(child: Divider(color: FluxerColors.divider)),
        ],
      ),
    );
  }
}
