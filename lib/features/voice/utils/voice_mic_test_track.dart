import 'package:fluxer_app/features/voice/domain/voice_settings_state.dart';
import 'package:fluxer_app/features/voice/services/voice_settings_applicator.dart';
import 'package:fluxer_app/features/voice/utils/voice_processing_profile.dart';
import 'package:livekit_client/livekit_client.dart';

Future<LocalAudioTrack> createMicTestAudioTrack({
  required VoiceSettingsApplicator applicator,
  required VoiceSettingsState settings,
}) async {
  final AudioCaptureOptions captureOptions = applicator
      .buildMicTestAudioCaptureOptions(settings);
  final LocalAudioTrack track = await LocalAudioTrack.create(captureOptions);

  final ResolvedVoiceProcessing processing = resolveVoiceProcessing(
    settings: settings,
    noiseFilterSupported: applicator.noiseFilterSupported,
  );
  final processor = applicator.noiseFilter;
  if (!processing.useNoiseFilter || processor == null) {
    return track;
  }

  await processor.setBypass(processing.bypassNoiseFilter);
  await track.mediaStream.getMediaTracks();
  await track.setProcessor(processor);
  return track;
}
