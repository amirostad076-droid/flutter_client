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
