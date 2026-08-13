import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/premium/should_show_premium_commerce_provider.dart';
import 'package:fluxer_app/features/settings/utils/user_settings_billing_utils.dart';

bool userSettingsShowBillingNav(WidgetRef ref) {
  if (!isOssWebCheckoutBuild) {
    return false;
  }
  return ref.watch(shouldShowPremiumCommerceProvider);
}

bool userSettingsShowBillingNavFromContainer(ProviderContainer container) {
  if (!isOssWebCheckoutBuild) {
    return false;
  }
  return container.read(shouldShowPremiumCommerceProvider);
}
