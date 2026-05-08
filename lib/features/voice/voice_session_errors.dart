import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

/// VoiceSessionState.errorMessage when camera access was denied
const String kVoiceSessionErrorCameraPermission = 'VOICE_ERR_CAMERA_PERM';

/// A generic screen-share toggle failure (unclassified).
const String kVoiceSessionErrorScreenShareToggle =
    'VOICE_ERR_SCREEN_SHARE_TOGGLE';

/// Screen-share permission being denied by the OS.
const String kVoiceSessionErrorScreenSharePermissionDenied =
    'VOICE_ERR_SCREEN_SHARE_PERM';

/// Screen-share toggle being invoked on a platform or device
/// that doesn't support it.
const String kVoiceSessionErrorScreenShareUnsupported =
    'VOICE_ERR_SCREEN_SHARE_UNSUPPORTED';

/// Maps a stored `VoiceSessionState.errorMessage` to a localized
/// human-readable string.
String resolveVoiceSessionErrorMessage(
  String message,
  FluxerLocalizations l10n,
) {
  switch (message) {
    case kVoiceSessionErrorCameraPermission:
      return l10n.voiceCameraPermissionRequired;
    case kVoiceSessionErrorScreenShareToggle:
      return l10n.voiceErrorScreenShareToggle;
    case kVoiceSessionErrorScreenSharePermissionDenied:
      return l10n.voiceErrorScreenSharePermissionDenied;
    case kVoiceSessionErrorScreenShareUnsupported:
      return l10n.voiceErrorScreenShareUnsupported;
    default:
      return message;
  }
}
