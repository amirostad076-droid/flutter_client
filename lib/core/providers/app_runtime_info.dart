import 'package:fluxer_app/core/build/app_build_environment.dart';
import 'package:fluxer_app/core/build/push_provider_kind.dart';

class AppRuntimeInfo {
  const AppRuntimeInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.environment,
    required this.pushProvider,
    required this.buildTimestamp,
    this.deviceModel,
  });
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final AppBuildEnvironment environment;
  final PushProviderKind pushProvider;
  final String buildTimestamp;
  final String? deviceModel;

  String get deviceModelLabel => deviceModel ?? '';
}
