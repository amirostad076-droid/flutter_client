import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as db;
import 'package:fluxer_app/core/permissions/channel_effective_permissions.dart';
import 'package:fluxer_app/core/permissions/permission.dart';
import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/data/read_state_repository.dart';
import 'package:fluxer_app/features/channels/data/read_state_utils.dart';
import 'package:fluxer_app/features/channels/domain/channel.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/domain/pending_attachment.dart';
import 'package:fluxer_app/features/chat/providers/chat_providers.dart';
import 'package:fluxer_app/features/chat/providers/chat_read_ack_gate.dart';
import 'package:fluxer_app/features/chat/providers/cloud_upload_controller.dart';
import 'package:fluxer_app/features/chat/providers/message_realtime_events.dart';
import 'package:fluxer_app/features/chat/providers/message_realtime_provider.dart';
import 'package:fluxer_app/features/chat/providers/slowmode_tracker.dart';
import 'package:fluxer_app/features/chat/providers/sticker_picker_provider.dart';
import 'package:fluxer_app/features/chat/providers/typing_sender.dart';
import 'package:fluxer_app/features/guilds/providers/guild_permissions_provider.dart';
import 'package:fluxer_app/shared/utils/snowflake_time.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_view_model.g.dart';

const _kPageSize = 30;
const _kReadAckMinInterval = Duration(seconds: 1);
const _kOutgoingAckDebounce = Duration(seconds: 3);

class ChatViewState {
  static const _unset = Object();

  final String channelId;
  final List<Message> messages;
  final Message? replyingTo;
  final Message? forwardingFrom;
  final Message? editingMessage;
  final String messageText;
  final int scrollToBottomSignal;
  final (String messageId, int version)? scrollToMessageSignal;
  final String? stickyUnreadMessageId;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMoreMessages;
  final String? errorMessage;

  const ChatViewState({
    required this.channelId,
    required this.messages,
    required this.replyingTo,
    required this.forwardingFrom,
    required this.editingMessage,
    required this.messageText,
    required this.scrollToBottomSignal,
    required this.isLoading,
    required this.isLoadingMore,
    required this.hasMoreMessages,
    required this.errorMessage,
    this.scrollToMessageSignal,
    this.stickyUnreadMessageId,
  });

  bool get canSend => messageText.trim().isNotEmpty;

  ChatViewState copyWith({
    String? channelId,
    List<Message>? messages,
    Object? replyingTo = _unset,
    Object? forwardingFrom = _unset,
    Object? editingMessage = _unset,
    String? messageText,
    int? scrollToBottomSignal,
    Object? scrollToMessageSignal = _unset,
    Object? stickyUnreadMessageId = _unset,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMoreMessages,
    Object? errorMessage = _unset,
  }) {
    return ChatViewState(
      channelId: channelId ?? this.channelId,
      messages: messages ?? this.messages,
      replyingTo: replyingTo == _unset
          ? this.replyingTo
          : replyingTo as Message?,
      forwardingFrom: forwardingFrom == _unset
          ? this.forwardingFrom
          : forwardingFrom as Message?,
      editingMessage: editingMessage == _unset
          ? this.editingMessage
          : editingMessage as Message?,
      messageText: messageText ?? this.messageText,
      scrollToBottomSignal: scrollToBottomSignal ?? this.scrollToBottomSignal,
      scrollToMessageSignal: scrollToMessageSignal == _unset
          ? this.scrollToMessageSignal
          : scrollToMessageSignal as (String, int)?,
      stickyUnreadMessageId: stickyUnreadMessageId == _unset
          ? this.stickyUnreadMessageId
          : stickyUnreadMessageId as String?,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMoreMessages: hasMoreMessages ?? this.hasMoreMessages,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

@Riverpod(keepAlive: true)
class ChatViewModel extends _$ChatViewModel {
  StreamSubscription<MessageRealtimeEvent>? _eventsSub;
  final ChatReadAckGate _readAckGate = ChatReadAckGate(
    minInterval: _kReadAckMinInterval,
  );
  Timer? _readAckRetryTimer;
  final Map<String, Timer> _outgoingAckTimers = <String, Timer>{};
  final Set<String> _loadedUnreadBoundaryKeys = <String>{};
  bool _readViewportActive = false;
  bool _readViewportNearBottom = true;
  int _nonceTimestampMs = 0;
  int _nonceSequence = 0;

  @override
  ChatViewState build() {
    final bus = ref.watch(messageRealtimeBusProvider);
    unawaited(_eventsSub?.cancel());
    _eventsSub = bus.stream.listen(_onRealtimeEvent);
    ref
      ..listen<bool>(appUiForegroundProvider, (previous, next) {
        if (!next) {
          _readAckRetryTimer?.cancel();
          return;
        }
        unawaited(ackCurrentChannel());
      })
      ..onDispose(() {
        _readAckRetryTimer?.cancel();
        for (final timer in _outgoingAckTimers.values) {
          timer.cancel();
        }
        _outgoingAckTimers.clear();
        unawaited(_eventsSub?.cancel());
      });
    return const ChatViewState(
      channelId: '',
      messages: [],
      replyingTo: null,
      forwardingFrom: null,
      editingMessage: null,
      messageText: '',
      scrollToBottomSignal: 0,
      isLoading: false,
      isLoadingMore: false,
      hasMoreMessages: true,
      errorMessage: null,
    );
  }

  Future<void> _onRealtimeEvent(MessageRealtimeEvent ev) async {
    final next = await _nextMessagesFor(ev);
    if (next != null) {
      state = state.copyWith(messages: next);
      if (ev is MessageCreated) {
        if (ev.event.message.author.id == ref.read(currentUserIdProvider)) {
          clearStickyUnread();
        }
        unawaited(ackCurrentChannel());
      }
    }
  }

  Future<List<Message>?> _nextMessagesFor(MessageRealtimeEvent ev) async {
    switch (ev) {
      case MessageCreated(:final event):
        if (event.message.channelId != state.channelId) {
          return null;
        }
        final msg = _toDomain(event.message);
        int matchedIndex = state.messages.indexWhere(
          (m) =>
              m.clientNonce != null &&
              msg.clientNonce != null &&
              m.clientNonce == msg.clientNonce,
        );
        if (matchedIndex == -1) {
          matchedIndex = _findOptimisticMatchForDelivered(msg);
        }
        if (matchedIndex != -1) {
          final updated = List<Message>.from(state.messages);
          updated[matchedIndex] = msg.copyWith(
            deliveryState: MessageDeliveryState.sent,
            sendError: null,
          );
          return updated;
        }
        if (state.messages.any((m) => m.id == msg.id)) {
          return null;
        }
        return [...state.messages, msg];
      case MessageUpdated(:final event):
        if (event.message.channelId != state.channelId) {
          return null;
        }
        return _replaceById(state.messages, _toDomain(event.message));
      case MessageDeleted(:final event):
        if (event.channelId != state.channelId) {
          return null;
        }
        return _removeIds(state.messages, {event.messageId});
      case MessagesDeletedBulk(:final event):
        if (event.channelId != state.channelId) {
          return null;
        }
        return _removeIds(state.messages, event.ids.toSet());
      case MessageReactionsChanged(:final channelId, :final messageId):
        if (channelId != state.channelId) {
          return null;
        }
        final row = await ref
            .read(fluxerDatabaseProvider)
            .messageDao
            .getMessage(messageId);
        if (row == null || state.channelId != channelId) {
          return null;
        }
        return _replaceById(state.messages, Message.fromRow(row));
    }
  }

  Message _toDomain(MessageResponseSchema schema) =>
      Message.fromSdk(schema, currentUserId: ref.read(currentUserIdProvider));

  List<Message>? _replaceById(List<Message> list, Message msg) {
    final idx = list.indexWhere((m) => m.id == msg.id);
    if (idx == -1) {
      return null;
    }
    final updated = List<Message>.from(list);
    updated[idx] = msg;
    return updated;
  }

  List<Message>? _removeIds(List<Message> list, Set<String> ids) {
    if (ids.isEmpty) {
      return null;
    }
    final filtered = list.where((m) => !ids.contains(m.id)).toList();
    return filtered.length == list.length ? null : filtered;
  }

  Future<void> switchChannel(
    String channelId, {
    String? targetMessageId,
    bool loadMessages = true,
  }) async {
    if (state.channelId.isNotEmpty && state.channelId != channelId) {
      final previousChannelId = state.channelId;
      _readAckRetryTimer?.cancel();
      _clearManualUnread(previousChannelId);
      _clearLoadedUnreadBoundaryKeys(previousChannelId);
    }
    if (targetMessageId != null) {
      if (state.channelId == channelId && state.isLoading) {
        return;
      }
      state = ChatViewState(
        channelId: channelId,
        messages: const [],
        replyingTo: null,
        forwardingFrom: null,
        editingMessage: null,
        messageText: '',
        scrollToBottomSignal: state.scrollToBottomSignal,
        isLoading: true,
        isLoadingMore: false,
        hasMoreMessages: true,
        errorMessage: null,
      );
      await _loadMessages(channelId, targetMessageId: targetMessageId);
      return;
    }
    if (!loadMessages) {
      if (state.channelId == channelId) {
        return;
      }
      state = ChatViewState(
        channelId: channelId,
        messages: const [],
        replyingTo: null,
        forwardingFrom: null,
        editingMessage: null,
        messageText: '',
        scrollToBottomSignal: state.scrollToBottomSignal,
        isLoading: false,
        isLoadingMore: false,
        hasMoreMessages: true,
        errorMessage: null,
      );
      return;
    }
    if (state.channelId == channelId && state.isLoading) {
      return;
    }
    state = ChatViewState(
      channelId: channelId,
      messages: const [],
      replyingTo: null,
      forwardingFrom: null,
      editingMessage: null,
      messageText: '',
      scrollToBottomSignal: state.scrollToBottomSignal,
      isLoading: true,
      isLoadingMore: false,
      hasMoreMessages: true,
      errorMessage: null,
    );
    await _loadMessages(channelId, targetMessageId: targetMessageId);
  }

  Future<void> _loadMessages(
    String channelId, {
    String? targetMessageId,
  }) async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final repo = ref.read(messageRepositoryProvider);
      final messages = await repo.getMessages(
        channelId: channelId,
        around: targetMessageId,
      );
      state = state.copyWith(
        messages: messages,
        isLoading: false,
        hasMoreMessages: messages.length >= _kPageSize,
      );
      if (targetMessageId == null) {
        final readState = await ref
            .read(fluxerDatabaseProvider)
            .readStateDao
            .getReadState(channelId);
        await _ensureUnreadBoundaryLoaded(channelId, readState: readState);
        unawaited(ackCurrentChannel());
      }
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to load messages: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to load messages',
      );
    }
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore ||
        !state.hasMoreMessages ||
        state.messages.isEmpty) {
      return;
    }

    state = state.copyWith(isLoadingMore: true);
    try {
      final repo = ref.read(messageRepositoryProvider);
      final oldestId = state.messages.first.id;
      final older = await repo.getMessages(
        channelId: state.channelId,
        before: oldestId,
      );
      state = state.copyWith(
        messages: [...older, ...state.messages],
        isLoadingMore: false,
        hasMoreMessages: older.length >= _kPageSize,
      );
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to load more: $e');
      state = state.copyWith(isLoadingMore: false);
    }
  }

  void setReadViewportActive({required bool isActive}) {
    _readViewportActive = isActive;
    if (!isActive) {
      _readAckRetryTimer?.cancel();
      return;
    }
    unawaited(ackCurrentChannel());
  }

  void updateReadViewport({required bool isNearBottom}) {
    _readViewportNearBottom = isNearBottom;
    if (!isNearBottom) {
      _readAckRetryTimer?.cancel();
      return;
    }
    unawaited(ackCurrentChannel());
  }

  Future<void> ackCurrentChannel({bool force = false}) async {
    final channelId = state.channelId;
    final now = DateTime.now();
    final isReadViewportEligible =
        _readViewportActive && ref.read(appUiForegroundProvider);
    final database = ref.read(fluxerDatabaseProvider);
    final readState = await database.readStateDao.getReadState(channelId);
    if (force) {
      _readAckGate.clearManualUnread(channelId);
    } else if (readState?.manual ?? false) {
      _readAckRetryTimer?.cancel();
      _readAckGate.markManualUnread(channelId);
      return;
    }
    if (!(readState?.manual ?? false)) {
      _readAckGate.clearManualUnread(channelId);
    }
    if (!_readAckGate.canAttemptAck(
      channelId: channelId,
      isActive: isReadViewportEligible,
      isNearBottom: _readViewportNearBottom,
      now: now,
      force: force,
    )) {
      final retryDelay = _readAckGate.retryDelay(
        channelId: channelId,
        isActive: isReadViewportEligible,
        isNearBottom: _readViewportNearBottom,
        now: now,
      );
      if (retryDelay != null && retryDelay > Duration.zero) {
        _scheduleReadAckRetry(retryDelay);
      }
      return;
    }

    _readAckRetryTimer?.cancel();
    _readAckGate.markAttemptStarted(channelId, now: now);
    final hadMentions = (readState?.mentionCount ?? 0) > 0;
    try {
      if (!force) {
        await _ensureUnreadBoundaryLoaded(channelId, readState: readState);
        await _preserveStickyUnreadBeforeAck(channelId, readState: readState);
      }
      final repository = ReadStateRepository(
        ref.read(fluxerClientProvider),
        database,
      );
      final ackedMessageId = await repository.applyLocalAckLatest(channelId);
      if (ackedMessageId != null) {
        _scheduleOutgoingAck(
          repository: repository,
          channelId: channelId,
          messageId: ackedMessageId,
          immediate: hadMentions || force,
        );
      }
      _readAckGate.clearManualUnread(channelId);
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to ack channel: $e');
    } finally {
      _readAckGate.markAttemptFinished(channelId);
    }
  }

  void _scheduleOutgoingAck({
    required ReadStateRepository repository,
    required String channelId,
    required String messageId,
    required bool immediate,
  }) {
    _outgoingAckTimers.remove(channelId)?.cancel();
    if (immediate) {
      unawaited(_dispatchOutgoingAck(repository, channelId, messageId));
      return;
    }
    _outgoingAckTimers[channelId] = Timer(_kOutgoingAckDebounce, () {
      _outgoingAckTimers.remove(channelId);
      unawaited(_dispatchOutgoingAck(repository, channelId, messageId));
    });
  }

  Future<void> _dispatchOutgoingAck(
    ReadStateRepository repository,
    String channelId,
    String messageId,
  ) async {
    try {
      await repository.sendAckHttp(channelId, messageId);
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to send ack HTTP: $e');
    }
  }

  void _flushOutgoingAck(String channelId) {
    final timer = _outgoingAckTimers.remove(channelId);
    if (timer != null) {
      timer.cancel();
    }
  }

  void _scheduleReadAckRetry(Duration delay) {
    _readAckRetryTimer?.cancel();
    _readAckRetryTimer = Timer(delay, () {
      _readAckRetryTimer = null;
      unawaited(ackCurrentChannel());
    });
  }

  Future<void> _ensureUnreadBoundaryLoaded(
    String channelId, {
    required db.ReadState? readState,
  }) async {
    if (state.channelId != channelId || state.messages.isEmpty) {
      return;
    }

    final ackMessageId = readState?.lastMessageId;
    if (ackMessageId == null || ackMessageId.isEmpty) {
      return;
    }

    final oldestLoadedId = state.messages.first.id;
    if (compareSnowflakeIds(oldestLoadedId, ackMessageId) <= 0) {
      return;
    }

    final latestLoadedId = state.messages.last.id;
    if (compareSnowflakeIds(latestLoadedId, ackMessageId) <= 0) {
      return;
    }

    final key = _unreadBoundaryKey(channelId, ackMessageId);
    if (_loadedUnreadBoundaryKeys.contains(key)) {
      return;
    }
    _loadedUnreadBoundaryKeys.add(key);

    try {
      final messages = await ref
          .read(messageRepositoryProvider)
          .getMessages(channelId: channelId, after: ackMessageId);
      if (messages.isEmpty || state.channelId != channelId) {
        return;
      }
      state = state.copyWith(
        messages: _mergeMessages(state.messages, messages),
      );
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to load unread boundary: $e');
    }
  }

  Future<void> _preserveStickyUnreadBeforeAck(
    String channelId, {
    required db.ReadState? readState,
  }) async {
    if (state.channelId != channelId || state.stickyUnreadMessageId != null) {
      return;
    }
    final currentUserId = ref.read(currentUserIdProvider);
    final stickyUnreadMessageId = oldestUnreadMessageId(
      messageIds: state.messages
          .where((message) => !_isOwnMessage(message, currentUserId))
          .map((message) => message.id),
      ackLastMessageId: readState?.lastMessageId,
    );
    if (stickyUnreadMessageId == null) {
      return;
    }
    state = state.copyWith(stickyUnreadMessageId: stickyUnreadMessageId);
  }

  bool _isOwnMessage(Message message, String? currentUserId) {
    return currentUserId != null &&
        currentUserId.isNotEmpty &&
        message.authorId == currentUserId;
  }

  List<Message> _mergeMessages(List<Message> current, List<Message> incoming) {
    final byId = <String, Message>{
      for (final message in current) message.id: message,
    };
    for (final message in incoming) {
      byId[message.id] = message;
    }
    final merged = byId.values.toList()
      ..sort((a, b) {
        final byId = compareSnowflakeIds(a.id, b.id);
        if (byId != 0) {
          return byId;
        }
        return a.timestamp.compareTo(b.timestamp);
      });
    return merged;
  }

  String _unreadBoundaryKey(String channelId, String ackMessageId) =>
      '$channelId:$ackMessageId';

  void _clearLoadedUnreadBoundaryKeys(String channelId) {
    _loadedUnreadBoundaryKeys.removeWhere(
      (key) => key.startsWith('$channelId:'),
    );
  }

  void _clearManualUnread(String channelId) =>
      _setChannelManual(channelId, manual: false);

  void _setChannelManual(String channelId, {required bool manual}) {
    if (channelId.isEmpty) {
      return;
    }
    if (manual) {
      _readAckGate.markManualUnread(channelId);
    } else {
      _readAckGate.clearManualUnread(channelId);
    }
    unawaited(
      ref
          .read(fluxerDatabaseProvider)
          .readStateDao
          .setManual(channelId, manual: manual),
    );
  }

  void clearStickyUnread() {
    if (state.stickyUnreadMessageId != null) {
      state = state.copyWith(stickyUnreadMessageId: null);
    }
  }

  void clearStickyUnreadFor(String channelId) {
    if (state.channelId != channelId) {
      return;
    }
    clearStickyUnread();
  }

  void cancelPendingOutgoingAck(String channelId) =>
      _flushOutgoingAck(channelId);

  void applyExternalAck(String channelId, {required bool manual}) {
    if (channelId.isEmpty) {
      return;
    }
    _flushOutgoingAck(channelId);
    if (manual) {
      _readAckGate.markManualUnread(channelId);
    } else {
      _readAckGate.clearManualUnread(channelId);
    }
    if (state.channelId == channelId) {
      clearStickyUnread();
    }
  }

  void clearStickyUnreadAfterBuildForCurrentChannel() {
    final channelId = state.channelId;
    unawaited(
      Future<void>(() {
        if (state.channelId != channelId) {
          return;
        }
        clearStickyUnread();
      }),
    );
  }

  void clearCurrentManualUnread() => _clearManualUnread(state.channelId);

  Future<void> markCurrentChannelRead() async {
    final channelId = state.channelId;
    if (channelId.isEmpty) {
      return;
    }
    _readAckRetryTimer?.cancel();
    _flushOutgoingAck(channelId);
    _readAckGate.clearManualUnread(channelId);
    clearStickyUnread();
    try {
      await ReadStateRepository(
        ref.read(fluxerClientProvider),
        ref.read(fluxerDatabaseProvider),
      ).ackLatest(channelId);
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to mark channel read: $e');
    }
  }

  Future<void> markMessageUnread(String messageId) async {
    final channelId = state.channelId;
    if (channelId.isEmpty || messageId.isEmpty) {
      return;
    }
    try {
      _flushOutgoingAck(channelId);
      await ReadStateRepository(
        ref.read(fluxerClientProvider),
        ref.read(fluxerDatabaseProvider),
      ).markMessageUnread(
        channelId: channelId,
        messageId: messageId,
        currentUserId: ref.read(currentUserIdProvider),
      );
      _readAckRetryTimer?.cancel();
      _readAckGate.markManualUnread(channelId);
      clearStickyUnread();
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to mark unread: $e');
    }
  }

  Future<void> sendMessage() =>
      _sendContent(state.messageText.trim(), clearMessageText: true);

  Future<void> sendStickerMessage(StickerEntry sticker) => _sendContent(
    state.messageText.trim(),
    clearMessageText: true,
    stickerIds: [sticker.id],
  );

  Future<void> sendFavoriteMemeMessage(FavoriteMeme meme) =>
      _sendContent('', clearMessageText: true, favoriteMemeId: meme.id);

  Future<void> sendStandaloneMessage(String content) =>
      _sendContent(content.trim(), clearMessageText: false);

  Future<void> _sendContent(
    String text, {
    required bool clearMessageText,
    List<String> stickerIds = const [],
    String? favoriteMemeId,
  }) async {
    if (state.editingMessage != null) {
      await saveEditedMessage();
      return;
    }
    final String channelId = state.channelId;
    final String? currentUserId = ref.read(currentUserIdProvider);
    final List<PendingAttachment> pendingAttachments = ref
        .read(cloudUploadControllerProvider(channelId))
        .items;
    if (text.isEmpty &&
        stickerIds.isEmpty &&
        favoriteMemeId == null &&
        pendingAttachments.isEmpty) {
      return;
    }
    final channelRow = await ref
        .read(fluxerDatabaseProvider)
        .channelDao
        .getChannelById(channelId);
    final guildId = channelRow?.guildId ?? '';
    int? guildBits;
    if (guildId.isNotEmpty) {
      final int effectiveBits =
          await computeEffectiveGuildChannelPermissionBits(
            ref: ref,
            channelId: channelId,
          );
      final bool canSendMessages =
          hasPermission(effectiveBits, Permission.sendMessages) ||
          (channelRow != null &&
              channelTypeFromInt(channelRow.type) == ChannelType.voice &&
              hasPermission(effectiveBits, Permission.useTextInVoice));
      if (!canSendMessages) {
        return;
      }
      guildBits = await ref
          .read(guildPermissionsProvider.notifier)
          .getPermissions(guildId);
    }
    final rateLimit = channelRow?.rateLimitPerUser ?? 0;
    if (rateLimit > 0) {
      var isImmune = false;
      if (guildId.isNotEmpty && guildBits != null) {
        isImmune =
            hasPermission(guildBits, Permission.bypassSlowmode) ||
            hasPermission(guildBits, Permission.manageChannels) ||
            hasPermission(guildBits, Permission.manageMessages);
      }
      if (!isImmune) {
        final remaining = ref
            .read(slowmodeTrackerProvider.notifier)
            .remainingFor(channelId, rateLimit);
        if (remaining > Duration.zero) {
          return;
        }
      }
    }

    final replyToId = state.replyingTo?.id;
    final db.User? currentUser = currentUserId == null
        ? null
        : await ref
              .read(fluxerDatabaseProvider)
              .userDao
              .getUserById(currentUserId);
    final bool hasGlobalName =
        currentUser?.globalName?.trim().isNotEmpty ?? false;
    final String authorName = hasGlobalName
        ? currentUser!.globalName!
        : currentUser?.username ?? 'You';
    final String clientNonce = _createClientNonce(channelId);
    final Message optimisticMessage = _buildOptimisticMessage(
      channelId: channelId,
      content: text,
      replyToId: replyToId,
      stickerIds: stickerIds,
      currentUserId: currentUserId,
      authorName: authorName,
      authorAvatar: currentUser?.avatar,
      authorAvatarColor: currentUser?.avatarColor,
      clientNonce: clientNonce,
    );

    state = state.copyWith(
      replyingTo: null,
      forwardingFrom: null,
      messageText: clearMessageText ? '' : state.messageText,
      messages: [...state.messages, optimisticMessage],
      errorMessage: null,
    );

    try {
      final CloudUploadController uploadNotifier = ref.read(
        cloudUploadControllerProvider(channelId).notifier,
      );
      final prepared = await uploadNotifier.prepareForSend(
        favoriteMemePayload: favoriteMemeId != null,
      );
      final repo = ref.read(messageRepositoryProvider);
      final Message sent = await repo.sendMessage(
        channelId: channelId,
        content: text,
        replyToId: replyToId,
        clientNonce: clientNonce,
        stickerIds: stickerIds,
        favoriteMemeId: favoriteMemeId,
        attachmentMetadata: prepared.attachmentMetadata,
        attachmentFiles: prepared.attachmentFiles,
      );
      uploadNotifier.clearComposerAttachments();
      ref.read(slowmodeTrackerProvider.notifier).recordSend(channelId);
      if (state.channelId != channelId) {
        return;
      }
      final int optimisticIndex = state.messages.indexWhere(
        (m) => m.id == optimisticMessage.id,
      );
      final List<Message> nextMessages = _replaceOptimisticWithDelivered(
        messages: state.messages,
        optimisticId: optimisticIndex == -1 ? null : optimisticMessage.id,
        delivered: sent.copyWith(
          deliveryState: MessageDeliveryState.sent,
          sendError: null,
        ),
      );
      state = state.copyWith(
        messages: nextMessages,
        scrollToBottomSignal: state.scrollToBottomSignal + 1,
      );
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to send: $e');
      final int optimisticIndex = state.messages.indexWhere(
        (m) => m.id == optimisticMessage.id,
      );
      if (optimisticIndex == -1) {
        state = state.copyWith(errorMessage: 'Failed to send message');
        return;
      }
      final List<Message> nextMessages = List<Message>.from(state.messages);
      nextMessages[optimisticIndex] = nextMessages[optimisticIndex].copyWith(
        deliveryState: MessageDeliveryState.failed,
        sendError: 'Failed to send message',
      );
      state = state.copyWith(
        messages: nextMessages,
        errorMessage: 'Failed to send message',
      );
    }
  }

  Future<void> retryMessageSend(String messageId) async {
    final int messageIndex = state.messages.indexWhere(
      (m) => m.id == messageId,
    );
    if (messageIndex == -1) {
      return;
    }
    final Message message = state.messages[messageIndex];
    if (!message.hasFailed) {
      return;
    }
    final List<Message> pendingMessages = List<Message>.from(state.messages);
    pendingMessages[messageIndex] = message.copyWith(
      deliveryState: MessageDeliveryState.sending,
      sendError: null,
    );
    state = state.copyWith(messages: pendingMessages, errorMessage: null);
    try {
      final Message sent = await ref
          .read(messageRepositoryProvider)
          .sendMessage(
            channelId: message.channelId,
            content: message.content,
            replyToId: message.replyToId,
            clientNonce:
                message.clientNonce ?? _createClientNonce(message.channelId),
            stickerIds: message.stickers
                .map((MessageSticker s) => s.id)
                .toList(),
          );
      final List<Message> nextMessages = _replaceOptimisticWithDelivered(
        messages: state.messages,
        optimisticId: message.id,
        delivered: sent.copyWith(
          deliveryState: MessageDeliveryState.sent,
          sendError: null,
        ),
      );
      state = state.copyWith(messages: nextMessages);
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Retry failed: $e');
      final List<Message> nextMessages = List<Message>.from(state.messages);
      final int latestIndex = nextMessages.indexWhere(
        (m) => m.id == message.id,
      );
      if (latestIndex == -1) {
        return;
      }
      nextMessages[latestIndex] = nextMessages[latestIndex].copyWith(
        deliveryState: MessageDeliveryState.failed,
        sendError: 'Failed to send message',
      );
      state = state.copyWith(
        messages: nextMessages,
        errorMessage: 'Failed to send message',
      );
    }
  }

  void deleteFailedMessage(String messageId) {
    final int messageIndex = state.messages.indexWhere(
      (m) => m.id == messageId,
    );
    if (messageIndex == -1 || !state.messages[messageIndex].hasFailed) {
      return;
    }
    final List<Message>? next = _removeIds(state.messages, {messageId});
    if (next == null) {
      return;
    }
    state = state.copyWith(messages: next);
  }

  void startReply(Message message) {
    state = state.copyWith(replyingTo: message, editingMessage: null);
  }

  void cancelReply() {
    state = state.copyWith(replyingTo: null);
  }

  void startForward(Message message) {
    state = state.copyWith(forwardingFrom: message, editingMessage: null);
  }

  void cancelForward() {
    state = state.copyWith(forwardingFrom: null);
  }

  void scrollToMessage(String messageId) {
    final version = (state.scrollToMessageSignal?.$2 ?? 0) + 1;
    state = state.copyWith(scrollToMessageSignal: (messageId, version));
  }

  void updateMessageText(String text) {
    final previous = state.messageText;
    state = state.copyWith(messageText: text);
    if (text.isEmpty || text == previous) {
      return;
    }
    final channelId = state.channelId;
    if (channelId.isEmpty) {
      return;
    }
    unawaited(
      ref.read(typingSenderProvider.notifier).notifyUserTyping(channelId),
    );
  }

  void startEdit(Message message) {
    state = state.copyWith(
      editingMessage: message,
      replyingTo: null,
      forwardingFrom: null,
      messageText: message.content,
    );
  }

  void cancelEdit() {
    state = state.copyWith(editingMessage: null, messageText: '');
  }

  Future<void> saveEditedMessage() async {
    final Message? editingMessage = state.editingMessage;
    if (editingMessage == null) {
      return;
    }
    final String editedContent = state.messageText.trim();
    if (editedContent.isEmpty || editedContent == editingMessage.content) {
      state = state.copyWith(editingMessage: null, messageText: '');
      return;
    }
    try {
      final Message updatedMessage = await ref
          .read(messageRepositoryProvider)
          .editMessage(
            channelId: editingMessage.channelId,
            messageId: editingMessage.id,
            content: editedContent,
          );
      final List<Message>? nextMessages = _replaceById(
        state.messages,
        updatedMessage,
      );
      state = state.copyWith(
        messages: nextMessages ?? state.messages,
        editingMessage: null,
        messageText: '',
        errorMessage: null,
      );
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Failed to edit message: $e');
      state = state.copyWith(errorMessage: 'Failed to edit message');
    }
  }

  Future<void> toggleReaction(
    String messageId,
    String emoji, {
    String? emojiId,
    bool animated = false,
  }) async {
    final msgIndex = state.messages.indexWhere((m) => m.id == messageId);
    if (msgIndex == -1) {
      return;
    }

    final msg = state.messages[msgIndex];
    final existingIdx = msg.reactions.indexWhere(
      (r) => r.emoji == emoji && r.emojiId == emojiId,
    );
    final hasReacted =
        existingIdx != -1 && msg.reactions[existingIdx].hasReacted;

    final updatedReactions = List<Reaction>.from(msg.reactions);
    if (hasReacted) {
      final old = updatedReactions[existingIdx];
      if (old.count <= 1) {
        updatedReactions.removeAt(existingIdx);
      } else {
        updatedReactions[existingIdx] = Reaction(
          emoji: emoji,
          emojiId: emojiId,
          animated: animated,
          count: old.count - 1,
        );
      }
    } else if (existingIdx != -1) {
      final old = updatedReactions[existingIdx];
      updatedReactions[existingIdx] = Reaction(
        emoji: emoji,
        emojiId: emojiId,
        animated: animated,
        count: old.count + 1,
        hasReacted: true,
      );
    } else {
      updatedReactions.add(
        Reaction(
          emoji: emoji,
          emojiId: emojiId,
          animated: animated,
          count: 1,
          hasReacted: true,
        ),
      );
    }

    // Optimistic update.
    final updatedMessages = List<Message>.from(state.messages);
    updatedMessages[msgIndex] = msg.copyWith(reactions: updatedReactions);
    state = state.copyWith(messages: updatedMessages);

    final reaction = Reaction(
      emoji: emoji,
      emojiId: emojiId,
      animated: animated,
      count: 0,
    );

    try {
      final repo = ref.read(messageRepositoryProvider);
      if (hasReacted) {
        await repo.removeReaction(
          channelId: state.channelId,
          messageId: messageId,
          emoji: reaction.apiParam,
        );
      } else {
        await repo.addReaction(
          channelId: state.channelId,
          messageId: messageId,
          emoji: reaction.apiParam,
        );
        // Track frecency on successful add.
        final db = ref.read(fluxerDatabaseProvider);
        unawaited(db.emojiUsageDao.trackUsage(reaction.frecencyKey));
      }
    } on Exception catch (e) {
      debugPrint('[ChatViewModel] Reaction failed: $e');
    }
  }

  Message _buildOptimisticMessage({
    required String channelId,
    required String content,
    required String? replyToId,
    required List<String> stickerIds,
    required String? currentUserId,
    required String authorName,
    required String? authorAvatar,
    required int? authorAvatarColor,
    required String clientNonce,
  }) {
    final DateTime now = DateTime.now();
    return Message(
      id: clientNonce,
      channelId: channelId,
      authorId: currentUserId ?? '',
      authorName: authorName,
      authorAvatar: authorAvatar,
      authorAvatarColor: authorAvatarColor,
      content: content,
      timestamp: now,
      replyToId: replyToId,
      stickers: stickerIds
          .map(
            (String stickerId) =>
                MessageSticker(id: stickerId, name: '', animated: false),
          )
          .toList(),
      deliveryState: MessageDeliveryState.sending,
      clientNonce: clientNonce,
    );
  }

  String _createClientNonce(String channelId) {
    final int timestampMs = DateTime.now().millisecondsSinceEpoch;
    if (timestampMs == _nonceTimestampMs) {
      _nonceSequence = (_nonceSequence + 1) & 0xFFF;
    } else {
      _nonceTimestampMs = timestampMs;
      _nonceSequence = 0;
    }
    final int timestampPart = timestampMs - kSnowflakeEpochMs;
    const int workerId = 1;
    final int nonce = (timestampPart << 22) | (workerId << 12) | _nonceSequence;
    return nonce.toString();
  }

  List<Message> _replaceOptimisticWithDelivered({
    required List<Message> messages,
    required String? optimisticId,
    required Message delivered,
  }) {
    final List<Message> updated = List<Message>.from(messages);
    int optimisticIndex = optimisticId == null
        ? -1
        : updated.indexWhere((Message m) => m.id == optimisticId);
    int deliveredIndex = updated.indexWhere(
      (Message m) => m.id == delivered.id,
    );
    if (optimisticIndex != -1 &&
        deliveredIndex != -1 &&
        deliveredIndex != optimisticIndex) {
      updated.removeAt(deliveredIndex);
      if (deliveredIndex < optimisticIndex) {
        optimisticIndex -= 1;
      }
      deliveredIndex = -1;
    }
    if (optimisticIndex != -1) {
      updated[optimisticIndex] = delivered;
      return updated;
    }
    if (deliveredIndex != -1) {
      updated[deliveredIndex] = delivered;
      return updated;
    }
    updated.add(delivered);
    return updated;
  }

  int _findOptimisticMatchForDelivered(Message delivered) {
    final String? currentUserId = ref.read(currentUserIdProvider);
    if (currentUserId == null || currentUserId.isEmpty) {
      return -1;
    }
    for (int i = state.messages.length - 1; i >= 0; i--) {
      final Message candidate = state.messages[i];
      if (!candidate.isSending) {
        continue;
      }
      if (candidate.authorId != currentUserId) {
        continue;
      }
      if (candidate.channelId != delivered.channelId) {
        continue;
      }
      if (candidate.content != delivered.content) {
        continue;
      }
      if (candidate.replyToId != delivered.replyToId) {
        continue;
      }
      final Duration timestampDiff = delivered.timestamp
          .difference(candidate.timestamp)
          .abs();
      if (timestampDiff > const Duration(seconds: 30)) {
        continue;
      }
      return i;
    }
    return -1;
  }
}
