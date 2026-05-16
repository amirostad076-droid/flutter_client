import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as drift_db;
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxer_app/features/chat/data/chat_unread_summary.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/delete_message_confirm_modal.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/message_item.dart';
import 'package:fluxer_app/features/chat/presentation/'
    'widgets/system_message.dart';
import 'package:fluxer_app/features/channels/providers/channel_list_view_model.dart';
import 'package:fluxer_app/features/chat/providers/chat_view_model.dart';
import 'package:fluxer_app/features/chat/utils/message_delete_permissions.dart';
import 'package:fluxer_app/features/dm/providers/dm_view_model.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:fluxer_app/shared/utils/chat_context_utils.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

const _kLoadMoreThreshold = 200.0;
const _kReadBottomThreshold = 24.0;
const _kUnreadDividerHeight = 16.0;
const _kUnreadDateDividerHeight = 20.0;

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
      ..clearCurrentManualUnread()
      ..clearStickyUnreadAfterBuildForCurrentChannel();
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

  void _onUnreadBarTap() {
    _onScrollToBottom();
    unawaited(_chatViewModel.markCurrentChannelRead());
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
    final String channelId = state.channelId;
    final bool isDmChannel = channelId.isNotEmpty &&
        ref.watch(
          dmViewModelProvider.select(
            (DmViewState dmState) =>
                findDmById(dmState.conversations, channelId) != null,
          ),
        );
    final String? guildId = isDmChannel || channelId.isEmpty
        ? null
        : findChannelById(ref.watch(channelListViewModelProvider), channelId)
            ?.guildId;
    final int? guildPermissionBits = guildId == null || guildId.isEmpty
        ? null
        : ref.watch(guildPermissionsProvider.select((s) => s[guildId]));
    if (guildId != null &&
        guildId.isNotEmpty &&
        !ref.read(guildPermissionsProvider).containsKey(guildId)) {
      unawaited(
        ref.read(guildPermissionsProvider.notifier).getPermissions(guildId),
      );
    }
    final readState = state.channelId.isEmpty
        ? null
        : ref
              .watch(_messageListReadStateProvider(state.channelId))
              .asData
              ?.value;
    final unreadSummary = computeChatUnreadSummary(
      messages: messages.map(
        (message) =>
            ChatUnreadMessageRef(id: message.id, authorId: message.authorId),
      ),
      ackLastMessageId: readState?.lastMessageId,
      mentionCount: readState?.mentionCount ?? 0,
      currentUserId: currentUserId,
    );
    final oldestUnreadId = unreadSummary.oldestUnreadMessageId;
    final stickyUnreadId = state.stickyUnreadMessageId;
    final visualUnreadId = _visualUnreadId(
      messages: messages,
      stickyUnreadId: stickyUnreadId,
      oldestUnreadId: oldestUnreadId,
      currentUserId: currentUserId,
    );
    final unreadCount = unreadSummary.displayUnreadCount;
    final unreadSince = _messageTimestamp(messages, visualUnreadId);
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

            return _withMessageSeparators(
              context,
              message: msg,
              isNewDay: isNewDay,
              visualUnreadId: visualUnreadId,
              child: systemWidget,
            );
          }

          final isGrouped = !isNewDay && _shouldGroup(msg, prevMsg);

          final itemKey = _itemKeys.putIfAbsent(msg.id, GlobalKey.new);
          final bool canDelete = canDeleteMessage(
            message: msg,
            currentUserId: currentUserId,
            isDmChannel: isDmChannel,
            guildPermissionBits: guildPermissionBits,
          );
          final bubble = MessageItem(
            key: itemKey,
            message: msg,
            isGrouped: isGrouped,
            currentUserId: currentUserId,
            canDelete: canDelete,
            onReply: () =>
                ref.read(chatViewModelProvider.notifier).startReply(msg),
            onForward: () =>
                ref.read(chatViewModelProvider.notifier).startForward(msg),
            onEdit: () =>
                ref.read(chatViewModelProvider.notifier).startEdit(msg),
            onDelete: () => showDeleteMessageConfirmModal(
              context,
              ref,
              message: msg,
              guildId: guildId,
            ),
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

          return _withMessageSeparators(
            context,
            message: msg,
            isNewDay: isNewDay,
            visualUnreadId: visualUnreadId,
            child: bubble,
          );
        },
      );
    }

    final mediaQuery = MediaQuery.of(context);
    final scaleRatio = chatFontSize / 16.0;
    final combinedScaler = TextScaler.linear(
      mediaQuery.textScaler.scale(1) * scaleRatio,
    );

    final Widget scaledBody;
    if (!state.isLoading && messages.isNotEmpty && unreadCount > 0) {
      scaledBody = Stack(
        fit: StackFit.expand,
        children: [
          body,
          Positioned(
            top: 8,
            left: 12,
            right: 12,
            child: _buildNewMessagesBar(
              context,
              count: unreadCount,
              isEstimated: unreadSummary.isEstimated,
              since: unreadSince,
              onTap: _onUnreadBarTap,
            ),
          ),
        ],
      );
    } else {
      scaledBody = body;
    }

    return MediaQuery(
      data: mediaQuery.copyWith(textScaler: combinedScaler),
      child: scaledBody,
    );
  }

  String? _visualUnreadId({
    required List<Message> messages,
    required String? stickyUnreadId,
    required String? oldestUnreadId,
    required String? currentUserId,
  }) {
    if (stickyUnreadId == null) {
      return oldestUnreadId;
    }
    final hasVisibleSticky = messages.any(
      (message) =>
          message.id == stickyUnreadId &&
          !_isOwnMessage(message, currentUserId),
    );
    return hasVisibleSticky ? stickyUnreadId : oldestUnreadId;
  }

  bool _isOwnMessage(Message message, String? currentUserId) {
    return currentUserId != null &&
        currentUserId.isNotEmpty &&
        message.authorId == currentUserId;
  }

  DateTime? _messageTimestamp(List<Message> messages, String? messageId) {
    if (messageId == null) {
      return null;
    }
    for (final message in messages) {
      if (message.id == messageId) {
        return message.timestamp;
      }
    }
    return null;
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

  Widget _withMessageSeparators(
    BuildContext context, {
    required Message message,
    required bool isNewDay,
    required String? visualUnreadId,
    required Widget child,
  }) {
    final isUnreadBoundary = message.id == visualUnreadId;

    if (isNewDay) {
      return Column(
        children: [
          if (isUnreadBoundary)
            _buildUnreadDateSeparator(context, message.timestamp)
          else
            _buildDateSeparator(context, message.timestamp),
          child,
        ],
      );
    }

    if (isUnreadBoundary) {
      return Column(children: [_buildUnreadSeparator(context), child]);
    }

    return child;
  }

  Widget _buildUnreadSeparator(BuildContext context) {
    final danger = context.colors.statusDanger;
    return SizedBox(
      height: _kUnreadDividerHeight,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(child: _buildUnreadLine(danger)),
            _buildUnreadBadge(context, danger, height: _kUnreadDividerHeight),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadDateSeparator(BuildContext context, DateTime date) {
    final danger = context.colors.statusDanger;
    final local = date.toLocal();
    final formatted =
        '${_kMonthNames[local.month - 1]} ${local.day},'
        ' ${local.year}';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: SizedBox(
        height: _kUnreadDateDividerHeight,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Row(
              children: [
                Expanded(child: _buildUnreadLine(danger)),
                _buildUnreadBadge(
                  context,
                  danger,
                  height: _kUnreadDateDividerHeight,
                ),
              ],
            ),
            ColoredBox(
              color: context.colors.backgroundSecondaryLighter,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  formatted,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.smallText.copyWith(
                    color: danger,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    height: 1,
                    letterSpacing: 0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUnreadLine(Color color) {
    return Container(height: 2, color: color.withValues(alpha: 0.4));
  }

  Widget _buildUnreadBadge(
    BuildContext context,
    Color color, {
    required double height,
  }) {
    return Container(
      height: height,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(3),
      ),
      child: Text(
        'NEW',
        maxLines: 1,
        style: context.textStyles.smallText.copyWith(
          color: Colors.white.withValues(alpha: 0.9),
          fontSize: 10,
          fontWeight: FontWeight.w700,
          height: 1,
          letterSpacing: 0.5,
        ),
      ),
    );
  }

  Widget _buildNewMessagesBar(
    BuildContext context, {
    required int count,
    required bool isEstimated,
    required DateTime? since,
    required VoidCallback onTap,
  }) {
    final displayCount = unreadCountLabel(count, isEstimated: isEstimated);
    final messageLabel = count == 1 && !isEstimated
        ? '1 new message'
        : '$displayCount new';
    final sinceLabel = since == null ? '' : ' since ${_formatTime(since)}';

    return Material(
      color: context.colors.brandPrimary,
      elevation: 3,
      shadowColor: Colors.black.withValues(alpha: 0.22),
      borderRadius: BorderRadius.circular(8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          child: Row(
            children: [
              PhosphorIcon(
                PhosphorIconsRegular.envelopeOpen,
                color: context.colors.textOnBrandPrimary,
                size: 18,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$messageLabel$sinceLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: context.textStyles.smallText.copyWith(
                    color: context.colors.textOnBrandPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Mark Read',
                maxLines: 1,
                style: context.textStyles.smallText.copyWith(
                  color: context.colors.textOnBrandPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatTime(DateTime date) {
    final local = date.toLocal();
    final hour = local.hour == 0
        ? 12
        : local.hour > 12
        ? local.hour - 12
        : local.hour;
    final minute = local.minute.toString().padLeft(2, '0');
    final period = local.hour >= 12 ? 'PM' : 'AM';
    return '$hour:$minute $period';
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
