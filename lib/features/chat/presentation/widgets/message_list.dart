import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as drift_db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/message_item.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/system_message.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kLoadMoreThreshold = 200.0;
const _kReadBottomThreshold = 24.0;

// Riverpod does not export the concrete auto-dispose family type.
// ignore: specify_nonobvious_property_types
final _messageListReadStateProvider = StreamProvider.autoDispose
    .family<drift_db.ReadState?, String>((ref, channelId) {
      final db = ref.watch(fluxerDatabaseProvider);
      return db.readStateDao.watchReadState(channelId);
    });

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
  const MessageList({this.targetMessageId, super.key});

  final String? targetMessageId;

  @override
  ConsumerState<MessageList> createState() => _MessageListState();
}

class _MessageListState extends ConsumerState<MessageList> {
  final _scrollController = ScrollController();
  final _itemKeys = <String, GlobalKey>{};
  late final ChatViewModel _chatViewModel;
  String? _pendingScrollTarget;

  @override
  void initState() {
    super.initState();
    _chatViewModel = ref.read(chatViewModelProvider.notifier);
    _scrollController.addListener(_onScroll);
    _pendingScrollTarget = widget.targetMessageId;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _chatViewModel.setReadViewportActive(isActive: true);
      _syncReadViewport();
    });
  }

  @override
  void didUpdateWidget(MessageList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.targetMessageId != oldWidget.targetMessageId &&
        widget.targetMessageId != null) {
      _pendingScrollTarget = widget.targetMessageId;
    }
  }

  @override
  void dispose() {
    _chatViewModel
      ..setReadViewportActive(isActive: false)
      ..clearStickyUnread();
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
    _syncReadViewport();
  }

  void _syncReadViewport() {
    if (!_scrollController.hasClients) {
      return;
    }
    _chatViewModel.updateReadViewport(
      isNearBottom: _scrollController.position.pixels <= _kReadBottomThreshold,
    );
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

  /// Scrolls to [messageId]
  void _scrollToTarget(String messageId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !_scrollController.hasClients) {
        return;
      }

      final ctx = _itemKeys[messageId]?.currentContext;
      if (ctx != null) {
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.5,
          ),
        );
        return;
      }

      final messages = ref.read(chatViewModelProvider).messages;
      final idx = messages.indexWhere((m) => m.id == messageId);
      if (idx == -1) {
        return;
      }
      final reversedIdx = messages.length - 1 - idx;
      final extent = _scrollController.position.maxScrollExtent;
      final approx = (reversedIdx / messages.length * extent).clamp(
        0.0,
        extent,
      );
      _scrollController.jumpTo(approx);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final c = _itemKeys[messageId]?.currentContext;
          if (c == null) {
            return;
          }
          unawaited(
            Scrollable.ensureVisible(
              c,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              alignment: 0.5,
            ),
          );
        });
      });
    });
  }

  void _onScrollToMessage(String messageId) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) {
        return;
      }
      final messages = ref.read(chatViewModelProvider).messages;
      final idx = messages.indexWhere((m) => m.id == messageId);
      if (idx == -1) {
        return;
      }

      final existingCtx = _itemKeys[messageId]?.currentContext;
      if (existingCtx != null) {
        unawaited(
          Scrollable.ensureVisible(
            existingCtx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.5,
          ),
        );
        return;
      }

      final reversedIdx = messages.length - 1 - idx;
      final extent = _scrollController.position.maxScrollExtent;
      final approx = (reversedIdx / messages.length * extent).clamp(
        0.0,
        extent,
      );
      _scrollController.jumpTo(approx);

      WidgetsBinding.instance.addPostFrameCallback((_) {
        final ctx = _itemKeys[messageId]?.currentContext;
        if (ctx == null) {
          return;
        }
        unawaited(
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
            alignment: 0.5,
          ),
        );
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    ref
      ..listen<int>(
        chatViewModelProvider.select((state) => state.scrollToBottomSignal),
        (previous, next) {
          if (next != previous) {
            _onScrollToBottom();
          }
        },
      )
      ..listen<(String, int)?>(
        chatViewModelProvider.select((s) => s.scrollToMessageSignal),
        (previous, next) {
          if (next != null && next != previous) {
            _onScrollToMessage(next.$1);
          }
        },
      );

    final currentUserId = ref.watch(currentUserIdProvider);
    final state = ref.watch(chatViewModelProvider);
    final messages = state.messages;
    final readState = state.channelId.isEmpty
        ? null
        : ref
              .watch(_messageListReadStateProvider(state.channelId))
              .asData
              ?.value;
    final oldestUnreadId = oldestUnreadMessageId(
      messageIds: messages.map((message) => message.id),
      ackLastMessageId: readState?.lastMessageId,
    );
    final stickyUnreadId = state.stickyUnreadMessageId;
    final visualUnreadId =
        stickyUnreadId != null &&
            messages.any((message) => message.id == stickyUnreadId)
        ? stickyUnreadId
        : oldestUnreadId;
    final chatFontSize = ref.watch(
      themePreferenceProvider.select((s) => s.chatFontSize),
    );

    if (messages.isEmpty) {
      _itemKeys.clear();
    }

    // Scroll to target after load if it exists/
    if (!state.isLoading && _pendingScrollTarget != null) {
      final target = _pendingScrollTarget!;
      if (messages.any((m) => m.id == target)) {
        _pendingScrollTarget = null;
        _scrollToTarget(target);
      }
    }

    final Widget body;
    if (state.isLoading) {
      body = Center(
        child: FluxerLoadingSpinner(color: context.colors.brandPrimary),
      );
    } else if (messages.isEmpty) {
      body = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            PhosphorIcon(
              PhosphorIconsFill.chatCircleDots,
              size: 48,
              color: context.colors.textPrimaryMuted,
            ),
            const SizedBox(height: 16),
            Text(
              'No messages yet',
              style: TextStyle(
                color: context.colors.textPrimaryMuted,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Be the first to send a message!',
              style: TextStyle(
                color: context.colors.textTertiaryMuted,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    } else {
      // With reverse: true, index 0 is at the bottom
      // (newest). Messages in state are oldest-first,
      // so we read them from the end.
      final itemCount = messages.length + (state.isLoadingMore ? 1 : 0);

      body = ListView.builder(
        controller: _scrollController,
        reverse: true,
        padding: const EdgeInsets.only(top: 8, bottom: 33),
        itemCount: itemCount,
        itemBuilder: (context, index) {
          // Loading indicator at the very top
          if (index >= messages.length) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Center(
                child: FluxerLoadingSpinner(color: context.colors.brandPrimary),
              ),
            );
          }

          final msgIndex = messages.length - 1 - index;
          final msg = messages[msgIndex];
          final prevMsg = msgIndex > 0 ? messages[msgIndex - 1] : null;

          final isNewDay =
              prevMsg == null || !_isSameDay(msg.timestamp, prevMsg.timestamp);

          if (msg.isSystemMessage) {
            final systemWidget = SystemMessage(
              key: ValueKey(msg.id),
              message: msg,
            );

            final Widget content = isNewDay
                ? Column(
                    children: [
                      _buildDateSeparator(context, msg.timestamp),
                      systemWidget,
                    ],
                  )
                : systemWidget;

            return _withUnreadSeparator(
              context,
              messageId: msg.id,
              oldestUnreadId: visualUnreadId,
              child: content,
            );
          }

          final isGrouped = !isNewDay && _shouldGroup(msg, prevMsg);

          final itemKey = _itemKeys.putIfAbsent(msg.id, GlobalKey.new);
          final bubble = MessageItem(
            key: itemKey,
            message: msg,
            isGrouped: isGrouped,
            currentUserId: currentUserId,
            onReply: () =>
                ref.read(chatViewModelProvider.notifier).startReply(msg),
            onForward: () =>
                ref.read(chatViewModelProvider.notifier).startForward(msg),
            onEdit: () =>
                ref.read(chatViewModelProvider.notifier).startEdit(msg),
            onRetry: () => ref
                .read(chatViewModelProvider.notifier)
                .retryMessageSend(msg.id),
            onDeleteFailed: () => ref
                .read(chatViewModelProvider.notifier)
                .deleteFailedMessage(msg.id),
            onMarkAsUnread: () => ref
                .read(chatViewModelProvider.notifier)
                .markMessageUnread(msg.id),
            onReaction: (emoji, {String? emojiId, bool animated = false}) => ref
                .read(chatViewModelProvider.notifier)
                .toggleReaction(
                  msg.id,
                  emoji,
                  emojiId: emojiId,
                  animated: animated,
                ),
          );

          final Widget content = isNewDay
              ? Column(
                  children: [
                    _buildDateSeparator(context, msg.timestamp),
                    bubble,
                  ],
                )
              : bubble;

          return _withUnreadSeparator(
            context,
            messageId: msg.id,
            oldestUnreadId: visualUnreadId,
            child: content,
          );
        },
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final scaleRatio = chatFontSize / 16.0;
    final combinedScaler = TextScaler.linear(
      mediaQuery.textScaler.scale(1) * scaleRatio,
    );

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: combinedScaler),
      child: body,
    );
  }

  /// Whether [current] should be visually grouped
  /// with [previous] (same author, within 7 minutes,
  /// neither is a reply or forward).
  bool _shouldGroup(Message current, Message? previous) {
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
    final diff = current.timestamp.difference(previous.timestamp);
    return diff.inMinutes < 7;
  }

  bool _isSameDay(DateTime a, DateTime b) {
    final localA = a.toLocal();
    final localB = b.toLocal();
    return localA.year == localB.year &&
        localA.month == localB.month &&
        localA.day == localB.day;
  }

  Widget _withUnreadSeparator(
    BuildContext context, {
    required String messageId,
    required String? oldestUnreadId,
    required Widget child,
  }) {
    if (messageId != oldestUnreadId) {
      return child;
    }

    return Column(children: [_buildUnreadSeparator(context), child]);
  }

  Widget _buildUnreadSeparator(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.colors.brandPrimary)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              'New',
              style: context.textStyles.smallText.copyWith(
                color: context.colors.brandPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Expanded(child: Divider(color: context.colors.brandPrimary)),
        ],
      ),
    );
  }

  Widget _buildDateSeparator(BuildContext context, DateTime date) {
    final local = date.toLocal();
    final formatted =
        '${_kMonthNames[local.month - 1]} ${local.day},'
        ' ${local.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          Expanded(child: Divider(color: context.colors.borderColor)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(formatted, style: context.textStyles.smallText),
          ),
          Expanded(child: Divider(color: context.colors.borderColor)),
        ],
      ),
    );
  }
}
