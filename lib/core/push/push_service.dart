import 'package:fluxeron/core/push/push_message.dart';

abstract interface class PushService {
  Future<void> requestPermissions();
  Future<void> initialize();
  Future<String?> getToken();
  Stream<PushMessage> watchMessages();
}
