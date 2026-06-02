import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';

import 'package:fluxer_app/features/chat/utils/voice_message_constants.dart';
import 'package:fluxer_app/features/chat/utils/voice_message_wav_encoder.dart';

class VoiceWaveformResult {
  const VoiceWaveformResult({
    required this.duration,
    required this.waveform,
  });

  final int duration;
  final String waveform;
}

Uint8List buildWaveformBytes(Float32List channelData, double durationSeconds) {
  final int pointCount = math.min(
    kVoiceMessageWaveformMaxPoints,
    math.max(
      1,
      (durationSeconds / kVoiceMessageWaveformSampleIntervalSeconds).ceil(),
    ),
  );
  final int samplesPerPoint = math.max(
    1,
    channelData.length ~/ pointCount,
  );
  final List<double> magnitudes = List<double>.filled(pointCount, 0);
  double maxMagnitude = 0;
  for (int i = 0; i < pointCount; i++) {
    final int start = i * samplesPerPoint;
    final int end = math.min(channelData.length, start + samplesPerPoint);
    double sumSquares = 0;
    int count = 0;
    for (int j = start; j < end; j++) {
      final double sample = channelData[j];
      sumSquares += sample * sample;
      count++;
    }
    final double rms = count > 0 ? math.sqrt(sumSquares / count) : 0;
    magnitudes[i] = rms;
    if (rms > maxMagnitude) {
      maxMagnitude = rms;
    }
  }
  final Uint8List bytes = Uint8List(pointCount);
  if (maxMagnitude <= 0) {
    return bytes;
  }
  for (int i = 0; i < pointCount; i++) {
    final double normalised = (magnitudes[i] / maxMagnitude).clamp(0, 1);
    bytes[i] = math.min(255, (math.sqrt(normalised) * 255).round());
  }
  return bytes;
}

VoiceWaveformResult computeVoiceWaveformFromPcm(VoiceMessagePcmSlice pcm) {
  final Uint8List data = buildWaveformBytes(
    pcm.samples,
    pcm.durationSeconds,
  );
  final int durationSeconds = math.max(
    1,
    pcm.durationSeconds.round(),
  );
  return VoiceWaveformResult(
    duration: durationSeconds,
    waveform: base64Encode(data),
  );
}

VoiceWaveformResult computeVoiceWaveformFromWavBytes(Uint8List wavBytes) {
  final VoiceMessagePcmSlice? pcm = decodeWavMonoPcm(wavBytes);
  if (pcm == null) {
    return const VoiceWaveformResult(duration: 1, waveform: '');
  }
  return computeVoiceWaveformFromPcm(pcm);
}

List<double> computePeaksFromPcm(
  VoiceMessagePcmSlice pcm, {
  int binCount = kVoiceMessageTrimPeakBinCount,
}) {
  final int count = math.max(1, binCount);
  final int samplesPerBin = math.max(1, pcm.samples.length ~/ count);
  final List<double> peaks = List<double>.filled(count, 0);
  for (int i = 0; i < count; i++) {
    final int start = i * samplesPerBin;
    final int end = math.min(pcm.samples.length, start + samplesPerBin);
    double peak = 0;
    for (int j = start; j < end; j++) {
      final double abs = pcm.samples[j].abs();
      if (abs > peak) {
        peak = abs;
      }
    }
    peaks[i] = peak;
  }
  final double maxPeak = peaks.reduce(math.max);
  if (maxPeak <= 0) {
    return peaks;
  }
  return peaks.map((double v) => v / maxPeak).toList();
}
