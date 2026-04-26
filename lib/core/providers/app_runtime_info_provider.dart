import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/core/build/app_build_environment.dart';
import 'package:fluxer_app/core/build/push_provider_kind.dart';
import 'package:package_info_plus/package_info_plus.dart';

class AppRuntimeInfo {
  const AppRuntimeInfo({
    required this.appName,
    required this.packageName,
    required this.version,
    required this.buildNumber,
    required this.environment,
    required this.pushProvider,
    required this.buildTimestamp,
  });
  final String appName;
  final String packageName;
  final String version;
  final String buildNumber;
  final AppBuildEnvironment environment;
  final PushProviderKind pushProvider;
  final String buildTimestamp;
}

final FutureProvider<AppRuntimeInfo> appRuntimeInfoProvider =
    FutureProvider<AppRuntimeInfo>((Ref ref) async {
      final PackageInfo packageInfo = await PackageInfo.fromPlatform();
      return AppRuntimeInfo(
        appName: packageInfo.appName,
        packageName: packageInfo.packageName,
        version: packageInfo.version,
        buildNumber: packageInfo.buildNumber,
        environment: AppBuildConfig.environment,
        pushProvider: AppBuildConfig.pushProvider,
        buildTimestamp: AppBuildConfig.buildTimestamp,
      );
    });
