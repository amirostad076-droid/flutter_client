import 'package:fluxer_app/core/providers/app_ui_lifecycle_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'chat_auto_ack_allowed_provider.g.dart';

@Riverpod(keepAlive: true)
bool chatAutoAckAllowed(Ref ref) {
  return ref.watch(appUiForegroundProvider);
}
