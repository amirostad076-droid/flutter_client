import 'dart:async';

import 'package:fluxer_app/core/api/fluxer_client_provider.dart';
import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:fluxer_app/core/providers/gateway_ready_provider.dart';
import 'package:fluxer_app/features/channels/data/ack_batcher.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'ack_batcher_provider.g.dart';

@Riverpod(keepAlive: true)
AckBatcher ackBatcher(Ref ref) {
  final client = ref.watch(fluxerClientProvider);
  final batcher = AckBatcher(client: client);

  ref.listen<bool>(appUiForegroundProvider, (prev, next) {
    if (prev == true && next == false) {
      unawaited(batcher.flushPending(force: true));
    }
  });
  ref.listen<bool>(gatewayReadyProvider, (prev, next) {
    if (prev == true && next == false) {
      unawaited(batcher.flushPending(force: true));
    }
  });

  ref.onDispose(() {
    unawaited(batcher.dispose());
  });
  return batcher;
}
