import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_dart/export.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_reactors_provider.g.dart';

const int kMessageReactorsPageSize = 50;

class MessageReactorsState {
  const MessageReactorsState({
    required this.users,
    required this.hasMore,
    this.nextAfter,
    this.isLoadingMore = false,
    this.errorMessage,
  });

  final List<UserPartialResponse> users;
  final bool hasMore;
  final String? nextAfter;
  final bool isLoadingMore;
  final String? errorMessage;

  MessageReactorsState copyWith({
    List<UserPartialResponse>? users,
    bool? hasMore,
    String? nextAfter,
    bool? isLoadingMore,
    Object? errorMessage = _unset,
  }) {
    return MessageReactorsState(
      users: users ?? this.users,
      hasMore: hasMore ?? this.hasMore,
      nextAfter: nextAfter ?? this.nextAfter,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      errorMessage: errorMessage == _unset
          ? this.errorMessage
          : errorMessage as String?,
    );
  }
}

const Object _unset = Object();

@riverpod
class MessageReactors extends _$MessageReactors {
  @override
  Future<MessageReactorsState> build({
    required String channelId,
    required String messageId,
    required String emoji,
  }) async {
    final page = await _fetch(after: null);
    return page;
  }

  Future<void> loadMore() async {
    final current = state.asData?.value;
    if (current == null ||
        current.isLoadingMore ||
        !current.hasMore ||
        current.nextAfter == null) {
      return;
    }
    state = AsyncData(current.copyWith(isLoadingMore: true));
    try {
      final page = await _fetch(after: current.nextAfter);
      state = AsyncData(
        current.copyWith(
          users: [...current.users, ...page.users],
          hasMore: page.hasMore,
          nextAfter: page.nextAfter,
          isLoadingMore: false,
          errorMessage: null,
        ),
      );
    } on Exception {
      state = AsyncData(
        current.copyWith(
          isLoadingMore: false,
          errorMessage: 'Failed to load reactions',
        ),
      );
    }
  }

  Future<MessageReactorsState> _fetch({required String? after}) async {
    final client = ref.read(fluxerClientProvider);
    final response = await client.channels.listReactionUsersV2(
      channelId: channelId,
      messageId: messageId,
      emoji: emoji,
      limit: kMessageReactorsPageSize,
      after: after,
    );
    return MessageReactorsState(
      users: response.items,
      hasMore: response.hasMore,
      nextAfter: response.nextAfter,
    );
  }
}
