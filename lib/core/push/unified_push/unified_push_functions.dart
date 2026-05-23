import 'package:fluxer_app/core/push/services/unified_push_service.dart';
import 'package:fluxer_app/core/push/unified_push/unified_push_vapid_cache.dart';
import 'package:unifiedpush/unifiedpush.dart' as up;
import 'package:unifiedpush_ui/unifiedpush_ui.dart';

/// Adapter for [unifiedpush_ui] dialogs.
final class FluxerUnifiedPushFunctions extends UnifiedPushFunctions {
  FluxerUnifiedPushFunctions();

  @override
  Future<String?> getDistributor() {
    return up.UnifiedPush.getDistributor();
  }

  @override
  Future<List<String>> getDistributors() {
    return up.UnifiedPush.getDistributors();
  }

  @override
  Future<void> registerApp(String instance) async {
    await UnifiedPushService.instance.loadCachedVapidPublicKey();
    final String? vapid = await readCachedUnifiedPushVapidPublicKey();
    await UnifiedPushService.instance.applyVapidAndReregisterIfNeeded(vapid);
    await UnifiedPushService.instance.syncRegistration(force: true);
  }

  @override
  Future<void> saveDistributor(String distributor) async {
    await up.UnifiedPush.saveDistributor(distributor);
  }
}
