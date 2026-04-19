import 'dart:async';

import 'package:fluxer_app/features/chat/providers/message_realtime_events.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'message_realtime_provider.g.dart';

class MessageRealtimeBus {
  final StreamController<MessageRealtimeEvent> _controller =
      StreamController<MessageRealtimeEvent>.broadcast();

  Stream<MessageRealtimeEvent> get stream => _controller.stream;

  void emit(MessageRealtimeEvent event) {
    if (_controller.isClosed) {
      return;
    }
    _controller.add(event);
  }

  Future<void> dispose() => _controller.close();
}

@Riverpod(keepAlive: true)
MessageRealtimeBus messageRealtimeBus(Ref ref) {
  final bus = MessageRealtimeBus();
  ref.onDispose(bus.dispose);
  return bus;
}
