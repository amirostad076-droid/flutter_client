import 'package:audioplayers/audioplayers.dart';

final AudioContext kChatAttachmentAudioContext = AudioContext(
  iOS: AudioContextIOS(
    options: const <AVAudioSessionOptions>{AVAudioSessionOptions.mixWithOthers},
  ),
);

Future<void> configureChatAttachmentAudioContext(AudioPlayer player) {
  return player.setAudioContext(kChatAttachmentAudioContext);
}
