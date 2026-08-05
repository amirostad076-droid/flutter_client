import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/synced_preferences/engine/synced_preferences_store.dart';

Future<void> _pumpAsyncWork() async {
  for (var i = 0; i < 16; i++) {
    await pumpEventQueue();
  }
}

Future<void> flushSyncedPreferencesDebounce(
  SyncedPreferencesStore store,
) async {
  store.triggerDebouncedPushForTest();
  await _pumpAsyncWork();
}

Future<void> flushSyncedPreferencesRateLimitRetry(
  SyncedPreferencesStore store,
) async {
  store.triggerRateLimitRetryForTest();
  await _pumpAsyncWork();
}
