import 'package:fluxer_dart/gateway.dart';

sealed class MessageRealtimeEvent {
  const MessageRealtimeEvent();
}

class MessageCreated extends MessageRealtimeEvent {
  final MessageCreateEvent event;

  const MessageCreated(this.event);
}

class MessageUpdated extends MessageRealtimeEvent {
  final MessageUpdateEvent event;

  const MessageUpdated(this.event);
}

class MessageDeleted extends MessageRealtimeEvent {
  final MessageDeleteEvent event;

  const MessageDeleted(this.event);
}

class MessagesDeletedBulk extends MessageRealtimeEvent {
  final MessageDeleteBulkEvent event;

  const MessagesDeletedBulk(this.event);
}

class MessageReactionsChanged extends MessageRealtimeEvent {
  final String channelId;
  final String messageId;

  const MessageReactionsChanged({
    required this.channelId,
    required this.messageId,
  });
}
