import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fluxer_app/features/chat/utils/voice_message_waveform.dart';
import 'package:fluxer_app/features/chat/utils/voice_message_wav_encoder.dart';
import 'package:test/test.dart';

void main() {
  test('buildWaveformBytes returns normalized bytes', () {
    final Float32List samples = Float32List(4410);
    for (int i = 0; i < samples.length; i++) {
      samples[i] = math.sin(i / 20);
    }
    final Uint8List bytes = buildWaveformBytes(samples, 0.1);
    expect(bytes, isNotEmpty);
    expect(bytes.every((int b) => b >= 0 && b <= 255), isTrue);
  });

  test('computeVoiceWaveformFromWavBytes encodes duration', () {
    final Float32List samples = Float32List(44100);
    for (int i = 0; i < samples.length; i++) {
      samples[i] = 0.5 * math.sin(i / 100);
    }
    final Uint8List wav = encodePcmSliceToWav(
      samples: samples,
      sampleRate: 44100,
    );
    final VoiceWaveformResult result = computeVoiceWaveformFromWavBytes(wav);
    expect(result.duration, greaterThanOrEqualTo(1));
    expect(result.waveform, isNotEmpty);
  });
}
