import 'dart:async';

import 'package:fluxeron/core/push/push_message.dart';
import 'package:fluxeron/core/push/push_service.dart';

class UnifiedPushService implements PushService {
  const UnifiedPushService();
  @override
  Future<void> requestPermissions() async {
    // TODO(developer): Implement UnifiedPush permission flow.
  }

  @override
  Future<void> initialize() async {
    // TODO(developer): Implement UnifiedPush initialization flow.
  }

  @override
  Future<String?> getToken() async {
    // TODO(developer): Return UnifiedPush registration token.
    return null;
  }

  @override
  Stream<PushMessage> watchMessages() {
    // TODO(developer): Map UnifiedPush payloads into PushMessage stream.
    return const Stream<PushMessage>.empty();
  }
}
