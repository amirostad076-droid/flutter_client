import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/theme/fluxer_theme_extension.dart';
import 'package:fluxeron/features/chat/domain/message.dart';
import 'package:fluxeron/features/chat/presentation/'
    'widgets/message_bubble.dart';
import 'package:fluxeron/features/chat/presentation/'
    'widgets/system_message.dart';
import 'package:fluxeron/features/chat/providers/chat_view_model.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kLoadMoreThreshold = 200.0;

const _kMonthNames = [
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

/// The scrollable list of messages in the chat area.
///
/// Uses a reversed [ListView] so newest messages appear
/// at the bottom and scrolling up loads older messages.
class MessageList extends ConsumerStatefulWidget {
  const MessageList({super.key});

  @override
  ConsumerState<MessageList> createState() =>
      _MessageListState();
}

class _MessageListState
    extends ConsumerState<MessageList> {
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
    if (pos.pixels >=
        pos.maxScrollExtent - _kLoadMoreThreshold) {
      unawaited(
        ref
            .read(chatViewModelProvider.notifier)
            .loadMore(),
      );
    }
  }

  void _onScrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback(
      (_) {
        if (_scrollController.hasClients) {
          unawaited(
            _scrollController.animateTo(
              0,
              duration: const Duration(
                milliseconds: 200,
              ),
              curve: Curves.easeOut,
            ),
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<int>(
      chatViewModelProvider.select(
        (state) => state.scrollToBottomSignal,
      ),
      (previous, next) {
        if (next != previous) {
          _onScrollToBottom();
        }
      },
    );

    final state = ref.watch(chatViewModelProvider);
    final messages = state.messages;

    if (state.isLoading) {
      return Center(
        child: CircularProgressIndicator(
          color: context.colors.brandPrimary,
        ),
      );
    }

    if (messages.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment:
              MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.chatCircleDots,
              size: 48,
              color:
                  context.colors.textPrimaryMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: context
                    .colors.textPrimaryMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to send a message!',
              style: TextStyle(
                color: context
                    .colors.textTertiaryMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    // With reverse: true, index 0 is at the bottom
    // (newest). Messages in state are oldest-first,
    // so we read them from the end.
    final itemCount = messages.length +
        (state.isLoadingMore ? 1 : 0);

    return ListView.builder(
      controller: _scrollController,
      reverse: true,
      padding: const EdgeInsets.only(
        top: 8,
        bottom: 16,
      ),
      itemCount: itemCount,
      itemBuilder: (context, index) {
        // Loading indicator at the very top
        if (index >= messages.length) {
          return Padding(
            padding: const EdgeInsets.symmetric(
              vertical: 8,
            ),
            child: Center(
              child: SizedBox(
                width: 24,
                height: 24,
                child:
                    CircularProgressIndicator(
                      strokeWidth: 2,
                      color: context
                          .colors.brandPrimary,
                    ),
              ),
            ),
          );
        }

        final msgIndex =
            messages.length - 1 - index;
        final msg = messages[msgIndex];
        final prevMsg = msgIndex > 0
            ? messages[msgIndex - 1]
            : null;

        final isNewDay = prevMsg == null ||
            !_isSameDay(
              msg.timestamp,
              prevMsg.timestamp,
            );

        if (msg.isSystemMessage) {
          final systemWidget = SystemMessage(
            key: ValueKey(msg.id),
            message: msg,
          );

          if (isNewDay) {
            return Column(
              children: [
                _buildDateSeparator(
                  context,
                  msg.timestamp,
                ),
                systemWidget,
              ],
            );
          }

          return systemWidget;
        }

        final isGrouped = !isNewDay &&
            _shouldGroup(msg, prevMsg);

        final bubble = MessageBubble(
          key: ValueKey(msg.id),
          message: msg,
          isGrouped: isGrouped,
          onReply: () => ref
              .read(
                chatViewModelProvider.notifier,
              )
              .startReply(msg),
          onForward: () => ref
              .read(
                chatViewModelProvider.notifier,
              )
              .startForward(msg),
        );

        if (isNewDay) {
          return Column(
            children: [
              _buildDateSeparator(
                context,
                msg.timestamp,
              ),
              bubble,
            ],
          );
        }

        return bubble;
      },
    );
  }

  /// Whether [current] should be visually grouped
  /// with [previous] (same author, within 7 minutes,
  /// neither is a reply or forward).
  bool _shouldGroup(
    Message current,
    Message? previous,
  ) {
    if (previous == null) {
      return false;
    }
    if (current.isSystemMessage || previous.isSystemMessage) {
      return false;
    }
    if (current.authorId != previous.authorId) {
      return false;
    }
    if (current.isReply || current.isForwarded) {
      return false;
    }
    if (previous.isReply || previous.isForwarded) {
      return false;
    }
    final diff = current.timestamp
        .difference(previous.timestamp);
    return diff.inMinutes < 7;
  }

  bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year &&
      a.month == b.month &&
      a.day == b.day;

  Widget _buildDateSeparator(
    BuildContext context,
    DateTime date,
  ) {
    final formatted =
        '${_kMonthNames[date.month - 1]} ${date.day},'
        ' ${date.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 8,
      ),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: context.colors.borderColor,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: 8,
            ),
            child: Text(
              formatted,
              style:
                  context.textStyles.smallText,
            ),
          ),
          Expanded(
            child: Divider(
              color: context.colors.borderColor,
            ),
          ),
        ],
      ),
    );
  }
}
