import 'package:fluxer_app/features/voice/utils/screen_share_capability.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'screen_share_capability_provider.g.dart';

/// Resolves once per app run with the device's screen-share capability.
/// Used by the voice control bar to hide the screen-share button on
/// platforms or devices where screen sharing isn't supported.
@Riverpod(keepAlive: true)
Future<bool> screenShareCapability(Ref ref) {
  return isScreenShareSupportedOnPlatform();
}
