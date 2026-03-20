import 'package:fluxeron/core/build/app_build_environment.dart';
import 'package:fluxeron/core/build/push_provider_kind.dart';

class AppBuildConfig {
  const AppBuildConfig._();
  // ignore: do_not_use_environment -- compile-time build flavor config
  static const String _environmentValue = String.fromEnvironment(
    'APP_ENVIRONMENT',
    defaultValue: 'production',
  );
  // ignore: do_not_use_environment -- compile-time build flavor config
  static const String _pushProviderValue = String.fromEnvironment(
    'PUSH_PROVIDER',
    defaultValue: 'apple',
  );
  static AppBuildEnvironment get environment {
    switch (_environmentValue) {
      case 'canary':
        return AppBuildEnvironment.canary;
      case 'production':
        return AppBuildEnvironment.production;
      default:
        return AppBuildEnvironment.production;
    }
  }

  static PushProviderKind get pushProvider {
    switch (_pushProviderValue) {
      case 'firebase':
        return PushProviderKind.firebaseMessaging;
      case 'unifiedpush':
        return PushProviderKind.unifiedPush;
      case 'apple':
        return PushProviderKind.apple;
      default:
        return PushProviderKind.apple;
    }
  }

  static bool get isCanary => environment == AppBuildEnvironment.canary;
  static bool get isProduction => environment == AppBuildEnvironment.production;
  static bool get isFirebaseMessagingEnabled =>
      pushProvider == PushProviderKind.firebaseMessaging;
}
