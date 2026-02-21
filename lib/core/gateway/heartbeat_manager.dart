import 'dart:async';

import 'package:flutter/foundation.dart';

/// Manages the heartbeat timer for the gateway WebSocket connection.
///
/// Sends a heartbeat payload at the interval specified by the server
/// and tracks whether an ACK was received before the next heartbeat.
class HeartbeatManager {
  HeartbeatManager({required this.onSendHeartbeat, required this.onTimeout});

  final VoidCallback onSendHeartbeat;
  final VoidCallback onTimeout;

  Timer? _timer;
  bool _ackReceived = true;

  void start(Duration interval) {
    stop();
    _ackReceived = true;
    _timer = Timer.periodic(interval, (_) {
      if (!_ackReceived) {
        onTimeout();
        stop();
        return;
      }
      _ackReceived = false;
      onSendHeartbeat();
    });
  }

  void ackReceived() {
    _ackReceived = true;
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}
