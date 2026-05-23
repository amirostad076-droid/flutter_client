import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/providers/gateway_reconnect_provider.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';

void main() {
  test('gatewayConnectionFailed tracks failure and reset', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    expect(container.read(gatewayConnectionFailedProvider), isFalse);
    container
        .read(gatewayConnectionFailedProvider.notifier)
        .setFailed(value: true);
    expect(container.read(gatewayConnectionFailedProvider), isTrue);
    container.read(gatewayConnectionFailedProvider.notifier).reset();
    expect(container.read(gatewayConnectionFailedProvider), isFalse);
  });

  test('marking failed clears serverReachable', () {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);

    container.read(serverReachableProvider.notifier).setReachable(value: true);
    container
        .read(gatewayConnectionFailedProvider.notifier)
        .setFailed(value: true);
    container.read(serverReachableProvider.notifier).setReachable(value: false);

    expect(container.read(serverReachableProvider), isFalse);
    expect(container.read(gatewayConnectionFailedProvider), isTrue);
  });
}
