// Mobile hold to record
const int kVoiceMessageMinSendDurationMs = 500;
const int kVoiceMessageRecordingTickMs = 120;
const int kVoiceMessageWaveformBarCount = 24;
const int kVoiceMessageRecordingSampleRate = 44100;
const int kVoiceMessageLivePcmWindowSamples = 256;
const int kVoiceMessageWaveformUpdateIntervalMs = 70;
const int kVoiceMessageLockDragMinVerticalDeltaPx = 52;
const int kVoiceMessageLockDragMaxHorizontalDeltaPx = 96;

const int kVoiceMessageLiveWaveformViewportHeightPx = 96;
const double kVoiceMessageLiveWaveformBarWidthPx = 3;
const double kVoiceMessageLiveWaveformBarGapPx = 2;
const int kVoiceMessageLiveWaveformRecentBarCount = 8;
const double kVoiceMessageLiveWaveformMaxBarHeightRatio = 0.85;
const double kVoiceMessageLiveWaveformMinVisibleHeightPx = 3;

const int kVoiceMessageTrimPeakBinCount = 600;
const int kVoiceMessageLiveAnalyserIntervalMs = 60;
const int kVoiceMessageWaveformMaxPoints = 256;
const double kVoiceMessageWaveformSampleIntervalSeconds = 0.1;

const int kMessageFlagVoiceMessage = 1 << 13;

const String kVoiceMessageFilename = 'voice-message.wav';
