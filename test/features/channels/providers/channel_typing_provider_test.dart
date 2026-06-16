import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/features/channels/providers/channel_typing_provider.dart';
import 'package:fluxer_app/features/gateway/providers/gateway_event_providers.dart';

void main() {
  ProviderContainer makeContainer() {
    final container = ProviderContainer(
      overrides: [currentUserIdProvider.overrideWithValue('me')],
    );
    addTearDown(container.dispose);
    return container;
  }

  test('reports typing only for the channel a remote user types in', () {
    final container = makeContainer();
    container.read(typingIndicatorsProvider.notifier).addTyping('A', 'u1');

    expect(container.read(channelHasTypingProvider('A')), isTrue);
    expect(container.read(channelHasTypingProvider('B')), isFalse);
  });

  test('ignores typing from the current user', () {
    final container = makeContainer();
    container.read(typingIndicatorsProvider.notifier).addTyping('A', 'me');

    expect(container.read(channelHasTypingProvider('A')), isFalse);
  });

  test('keeps channels independent as typing changes', () {
    final container = makeContainer();
    container.read(typingIndicatorsProvider.notifier).addTyping('A', 'u1');
    container.read(typingIndicatorsProvider.notifier).addTyping('B', 'u2');

    expect(container.read(channelHasTypingProvider('A')), isTrue);
    expect(container.read(channelHasTypingProvider('B')), isTrue);

    container.read(typingIndicatorsProvider.notifier).removeTyping('B', 'u2');

    expect(container.read(channelHasTypingProvider('A')), isTrue);
    expect(container.read(channelHasTypingProvider('B')), isFalse);
  });
}
