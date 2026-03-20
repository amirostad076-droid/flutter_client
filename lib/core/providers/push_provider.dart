import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/push/push_service.dart';
import 'package:fluxeron/core/push/push_service_factory.dart';

final Provider<PushService> pushServiceProvider = Provider<PushService>((
  Ref ref,
) {
  return createPushService();
});
