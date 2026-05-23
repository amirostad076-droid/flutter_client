import 'package:fluxer_app/core/database/fluxer_database.dart';

/// Reads the cached VAPID public key without Riverpod (background UP isolate).
Future<String?> readCachedUnifiedPushVapidPublicKey() async {
  final FluxerDatabase database = FluxerDatabase();
  try {
    return await database.mobilePushRegistrationDao.getCachedVapidPublicKey();
  } finally {
    await database.close();
  }
}

/// Persists the VAPID key for the background isolate and later register calls.
Future<void> writeCachedUnifiedPushVapidPublicKey(String vapidPublicKey) async {
  if (vapidPublicKey.isEmpty) {
    return;
  }
  final FluxerDatabase database = FluxerDatabase();
  try {
    await database.mobilePushRegistrationDao.saveGlobalVapidPublicKey(
      vapidPublicKey,
    );
  } finally {
    await database.close();
  }
}
