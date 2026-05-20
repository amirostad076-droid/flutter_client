import 'package:flutter/foundation.dart';
import 'package:permission_handler/permission_handler.dart';

Future<bool> requestPushNotificationPermission() async {
  if (kIsWeb) {
    return false;
  }
  const Permission permission = Permission.notification;
  PermissionStatus status = await permission.status;
  if (status.isGranted || status.isProvisional) {
    return true;
  }
  if (status.isPermanentlyDenied) {
    if (kDebugMode) {
      debugPrint('[PushPermission] permanently denied');
    }
    return false;
  }
  status = await permission.request();
  if (kDebugMode) {
    debugPrint('[PushPermission] status after request: $status');
  }
  return status.isGranted || status.isProvisional;
}
