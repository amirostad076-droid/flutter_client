import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'gateway_ready_provider.g.dart';

/// Whether the gateway READY event has been fully processed.
///
/// Starts as `false` and is set to `true` after the READY handler commits
/// all initial data to the database. The router gates navigation to the
/// main UI on this provider so the user never sees empty screens.
@Riverpod(keepAlive: true)
class GatewayReady extends _$GatewayReady {
  @override
  bool build() => false;

  void setReady() {
    state = true;
  }

  void reset() {
    state = false;
  }
}
