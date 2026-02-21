import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:web_socket_channel/web_socket_channel.dart';

import 'package:fluxeron/core/database/fluxer_database.dart';
import 'package:fluxeron/core/gateway/gateway_event.dart';
import 'package:fluxeron/core/gateway/gateway_event_handler.dart';
import 'package:fluxeron/core/gateway/heartbeat_manager.dart';

/// Gateway connection states.
enum GatewayStatus { disconnected, connecting, connected, reconnecting }

/// WebSocket lifecycle manager for the Fluxer gateway.
///
/// Handles connection, authentication (IDENTIFY), heartbeat, event
/// dispatch, and automatic reconnection with exponential backoff.
class GatewayClient {
  GatewayClient({
    required FluxerDatabase db,
    required this.gatewayUrl,
    TypingCallback? onTypingStart,
  }) : _handler = GatewayEventHandler(
         database: db,
         onTypingStart: onTypingStart,
       );

  final String gatewayUrl;
  final GatewayEventHandler _handler;

  WebSocketChannel? _channel;
  StreamSubscription<dynamic>? _subscription;
  HeartbeatManager? _heartbeat;

  String? _token;
  int _reconnectAttempts = 0;
  static const _kMaxReconnectAttempts = 5;

  final _statusController = StreamController<GatewayStatus>.broadcast();
  Stream<GatewayStatus> get statusStream => _statusController.stream;
  GatewayStatus _status = GatewayStatus.disconnected;
  GatewayStatus get status => _status;

  void _setStatus(GatewayStatus status) {
    _status = status;
    _statusController.add(status);
  }

  Uri get _connectUri {
    final base = Uri.parse(gatewayUrl);
    return base.replace(
      queryParameters: {'v': '1', 'encoding': 'json', 'compress': 'none'},
    );
  }

  Future<void> connect(String token) async {
    _token = token;
    _setStatus(GatewayStatus.connecting);

    _heartbeat = HeartbeatManager(
      onSendHeartbeat: _sendHeartbeat,
      onTimeout: _onHeartbeatTimeout,
    );

    try {
      _channel = WebSocketChannel.connect(_connectUri);
      await _channel!.ready;
      _setStatus(GatewayStatus.connected);

      _subscription = _channel!.stream.listen(
        _onMessage,
        onDone: _onDone,
        onError: _onError,
      );
    } on Exception catch (e) {
      debugPrint('[GatewayClient] Connection failed: $e');
      _setStatus(GatewayStatus.disconnected);
      unawaited(_reconnect());
    }
  }

  Future<void> disconnect() async {
    _heartbeat?.stop();
    await _subscription?.cancel();
    await _channel?.sink.close();
    _channel = null;
    _token = null;
    _reconnectAttempts = 0;
    _setStatus(GatewayStatus.disconnected);
  }

  void _onMessage(dynamic raw) {
    if (raw is! String) {
      return;
    }

    final payload = jsonDecode(raw) as Map<String, dynamic>;
    final op = payload['op'] as int?;
    final data = payload['d'] as Map<String, dynamic>?;

    switch (op) {
      case 10:
        // HELLO — start heartbeat and identify
        _reconnectAttempts = 0;
        final interval = (data?['heartbeat_interval'] as int?) ?? 45000;
        _heartbeat?.start(Duration(milliseconds: interval));
        _sendIdentify();
      case 11:
        // HEARTBEAT_ACK
        _heartbeat?.ackReceived();
      case 0:
        // DISPATCH — route to event handler
        final eventType = payload['t'] as String?;
        if (eventType != null && data != null) {
          final type = parseGatewayEvent(eventType);
          if (type != null) {
            _handler.handle(type, data);
          }
        }
    }
  }

  void _sendIdentify() {
    if (_token == null || _channel == null) {
      return;
    }
    _channel!.sink.add(
      jsonEncode({
        'op': 2,
        'd': {
          'token': _token,
          'properties': {r'$os': 'linux', r'$browser': 'fluxeron'},
        },
      }),
    );
  }

  void _sendHeartbeat() {
    _channel?.sink.add(jsonEncode({'op': 1, 'd': null}));
  }

  void _onHeartbeatTimeout() {
    debugPrint('[GatewayClient] Heartbeat timeout — reconnecting');
    unawaited(_channel?.sink.close());
  }

  static const _kFatalCloseCodes = {4002, 4003, 4004};

  void _onDone() {
    final code = _channel?.closeCode;
    final reason = _channel?.closeReason;
    debugPrint(
      '[GatewayClient] Connection closed '
      '(code: $code, reason: $reason)',
    );
    _heartbeat?.stop();
    if (code != null && _kFatalCloseCodes.contains(code)) {
      debugPrint('[GatewayClient] Fatal close code, not reconnecting');
      _setStatus(GatewayStatus.disconnected);
      return;
    }
    if (_token != null) {
      unawaited(_reconnect());
    }
  }

  void _onError(Object error) {
    debugPrint('[GatewayClient] Error: $error');
    _heartbeat?.stop();
    if (_token != null) {
      unawaited(_reconnect());
    }
  }

  Future<void> _reconnect() async {
    if (_reconnectAttempts >= _kMaxReconnectAttempts || _token == null) {
      _setStatus(GatewayStatus.disconnected);
      return;
    }

    _setStatus(GatewayStatus.reconnecting);
    _reconnectAttempts++;
    final delay = Duration(seconds: 1 << _reconnectAttempts);
    debugPrint(
      '[GatewayClient] Reconnect attempt $_reconnectAttempts '
      'in ${delay.inSeconds}s',
    );
    await Future<void>.delayed(delay);

    if (_token != null) {
      await connect(_token!);
    }
  }

  Future<void> dispose() async {
    await disconnect();
    await _statusController.close();
  }
}
