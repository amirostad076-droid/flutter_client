import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_session_recovery_provider.g.dart';

/// Incremented after each gateway READY/RESUMED [onReady] callback.
///
/// Consumers that only listen to [gatewayReadyProvider] false→true miss soft
/// reconnects on the same socket instance
@Riverpod(keepAlive: true)
class GatewaySessionRecovery extends _$GatewaySessionRecovery {
  @override
  int build() => 0;

  void bump() {
    state++;
  }
}
