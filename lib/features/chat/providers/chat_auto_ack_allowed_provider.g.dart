// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_auto_ack_allowed_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint, type=warning

@ProviderFor(chatAutoAckAllowed)
final chatAutoAckAllowedProvider = ChatAutoAckAllowedProvider._();

final class ChatAutoAckAllowedProvider
    extends $FunctionalProvider<bool, bool, bool>
    with $Provider<bool> {
  ChatAutoAckAllowedProvider._()
    : super(
        from: null,
        argument: null,
        retry: null,
        name: r'chatAutoAckAllowedProvider',
        isAutoDispose: false,
        dependencies: null,
        $allTransitiveDependencies: null,
      );

  @override
  String debugGetCreateSourceHash() => _$chatAutoAckAllowedHash();

  @$internal
  @override
  $ProviderElement<bool> $createElement($ProviderPointer pointer) =>
      $ProviderElement(pointer);

  @override
  bool create(Ref ref) {
    return chatAutoAckAllowed(ref);
  }

  /// {@macro riverpod.override_with_value}
  Override overrideWithValue(bool value) {
    return $ProviderOverride(
      origin: this,
      providerOverride: $SyncValueProvider<bool>(value),
    );
  }
}

String _$chatAutoAckAllowedHash() =>
    r'06ad786f6e4c4b81829cd1c398e6c6463501071e';
