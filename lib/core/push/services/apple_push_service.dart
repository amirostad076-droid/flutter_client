import 'dart:async';

import 'package:fluxeron/core/push/push_message.dart';
import 'package:fluxeron/core/push/push_service.dart';

class ApplePushService implements PushService {
  const ApplePushService();
  @override
  Future<void> requestPermissions() async {
    // TODO(developer): Implement APNs permission request.
  }

  @override
  Future<void> initialize() async {
    // TODO(developer): Implement APNs initialization flow.
  }

  @override
  Future<String?> getToken() async {
    // TODO(developer): Return APNs device token.
    return null;
  }

  @override
  Stream<PushMessage> watchMessages() {
    // TODO(developer): Map APNs payloads into PushMessage stream.
    return const Stream<PushMessage>.empty();
  }
}
