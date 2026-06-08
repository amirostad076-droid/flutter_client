import 'package:fluxer_app/core/providers/app_runtime_info_provider.dart';
import 'package:fluxer_app/features/shell/data/beta_warning_ack_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'beta_warning_controller.g.dart';

@Riverpod(keepAlive: true)
BetaWarningAckStorage betaWarningAckStorage(Ref ref) {
  return SecureBetaWarningAckStorage();
}

@Riverpod(keepAlive: true)
class BetaWarningController extends _$BetaWarningController {
  @override
  void build() {}

  Future<bool> shouldShow() async {
    final BetaWarningAckStorage storage = ref.read(
      betaWarningAckStorageProvider,
    );
    final AppRuntimeInfo runtimeInfo = await ref.read(
      appRuntimeInfoProvider.future,
    );
    final String? acknowledgedBuildNumber = await storage
        .readAcknowledgedBuildNumber();
    return acknowledgedBuildNumber != runtimeInfo.buildNumber;
  }

  Future<void> acknowledge() async {
    final BetaWarningAckStorage storage = ref.read(
      betaWarningAckStorageProvider,
    );
    final AppRuntimeInfo runtimeInfo = await ref.read(
      appRuntimeInfoProvider.future,
    );
    await storage.writeAcknowledgedBuildNumber(runtimeInfo.buildNumber);
  }
}
