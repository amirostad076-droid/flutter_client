import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/database/fluxer_database.dart' as database;
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/settings/providers/voice_settings_provider.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/features/ui/voice/voice_participant_media_tile.dart';
import 'package:fluxer_app/features/voice/domain/voice_settings_state.dart';
import 'package:fluxer_app/features/voice/providers/voice_channel_participants_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_pip_providers.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_provider.dart';
import 'package:fluxer_app/features/voice/providers/voice_session_state.dart';
import 'package:fluxer_app/features/voice/providers/voice_stream_audio_provider.dart';
import 'package:fluxer_app/features/voice/utils/voice_participant_tile_id.dart';
import 'package:fluxer_app/features/voice/utils/voice_participant_track_resolver.dart';
import 'package:fluxer_app/features/voice/utils/voice_stream_audio_utils.dart';
import 'package:fluxer_app/material_ui.dart';
import 'package:fluxer_dart/gateway.dart';
import 'package:livekit_client/livekit_client.dart';

class VoicePipVideo extends ConsumerWidget {
  const VoicePipVideo({required this.tileId, super.key});

  final String tileId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final VoiceSessionState voice = ref.watch(voiceSessionProvider);
    final String? key = voiceSessionParticipantsKey(voice);
    final parsed = parseVoiceParticipantTileId(tileId);
    if (key == null || parsed == null) {
      return const ColoredBox(color: Color(0xFF111111));
    }
    final List<VoiceChannelParticipantData> participants = ref.watch(
      voiceChannelParticipantsProvider(key),
    );
    VoiceChannelParticipantData? match;
    for (final VoiceChannelParticipantData participant in participants) {
      if (voiceParticipantTileId(
            voice: participant.voice,
            userId: participant.userId,
            source: parsed.source,
          ) ==
          tileId) {
        match = participant;
        break;
      }
    }
    if (match == null) {
      return const ColoredBox(color: Color(0xFF111111));
    }
    final String? me = ref.watch(currentUserIdProvider);
    final Participant? liveKit = resolveVoiceParticipant(
      room: voice.liveKitRoom,
      voice: match.voice,
      userId: match.userId,
      currentUserId: me,
      localConnectionId: voice.activeConnectionId,
    );
    final database.User? user = match.user;
    final Color background = user?.avatarColor == null
        ? context.colors.brandPrimary
        : Color(0xFF000000 | user!.avatarColor!);
    if (liveKit == null) {
      return _PipAvatarFallback(
        user: user,
        userId: match.userId,
        background: background,
      );
    }
    return _PipTrackView(
      participant: liveKit,
      source: parsed.source,
      isOwnCamera:
          parsed.source == VoiceParticipantTileSource.camera &&
          me != null &&
          match.userId == me,
      mirrorOwnCamera: ref.watch(
        voiceSettingsProvider.select(
          (VoiceSettingsState s) => s.shouldMirrorOwnCamera,
        ),
      ),
      voice: match.voice,
      user: user,
      userId: match.userId,
      background: background,
    );
  }
}

class _PipTrackView extends StatelessWidget {
  const _PipTrackView({
    required this.participant,
    required this.source,
    required this.isOwnCamera,
    required this.mirrorOwnCamera,
    required this.voice,
    required this.user,
    required this.userId,
    required this.background,
  });

  final Participant participant;
  final VoiceParticipantTileSource source;
  final bool isOwnCamera;
  final bool mirrorOwnCamera;
  final VoiceState voice;
  final database.User? user;
  final String userId;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: participant,
      builder: (BuildContext context, Widget? _) {
        final bool isScreen = source == VoiceParticipantTileSource.screenShare;
        final TrackPublication? publication = isScreen
            ? resolveScreenShareVideoPublication(
                participant: participant,
                requireTrack: false,
              )
            : resolveCameraPublicationAllowingNoTrack(participant);
        if (publication is RemoteTrackPublication && !publication.subscribed) {
          unawaited(publication.subscribe());
        }
        final Track? publicationTrack = publication?.track;
        final VideoTrack? track = publicationTrack is VideoTrack
            ? publicationTrack
            : null;
        TrackPublication? audioPublication;
        AudioTrack? audioTrack;
        if (isScreen) {
          audioPublication = resolveScreenShareAudioPublication(
            participant: participant,
            requireTrack: false,
          );
          if (audioPublication is RemoteTrackPublication &&
              !audioPublication.subscribed) {
            unawaited(audioPublication.subscribe());
          }
          final Track? audioPublicationTrack = audioPublication?.track;
          audioTrack = audioPublicationTrack is AudioTrack
              ? audioPublicationTrack
              : null;
        }
        final Widget fallback = _PipAvatarFallback(
          user: user,
          userId: userId,
          background: background,
        );
        if (track == null) {
          if (audioTrack == null) {
            return fallback;
          }
          return Stack(
            fit: StackFit.expand,
            children: <Widget>[
              fallback,
              _PipScreenShareAudio(
                streamKey: buildViewerStreamKey(
                  voice: voice,
                  isScreenShareTile: true,
                ),
                audioTrack: audioTrack,
              ),
            ],
          );
        }
        final VideoViewFit fit = isScreen
            ? VideoViewFit.contain
            : VideoViewFit.cover;
        final VideoViewMirrorMode mirrorMode;
        if (!isOwnCamera || isScreen) {
          mirrorMode = VideoViewMirrorMode.off;
        } else if (mirrorOwnCamera) {
          mirrorMode = VideoViewMirrorMode.mirror;
        } else {
          mirrorMode = VideoViewMirrorMode.off;
        }
        final Widget video = ColoredBox(
          color: background,
          child: VideoTrackRenderer(track, fit: fit, mirrorMode: mirrorMode),
        );
        if (audioTrack == null) {
          return video;
        }
        return Stack(
          fit: StackFit.expand,
          children: <Widget>[
            video,
            _PipScreenShareAudio(
              streamKey: buildViewerStreamKey(
                voice: voice,
                isScreenShareTile: true,
              ),
              audioTrack: audioTrack,
            ),
          ],
        );
      },
    );
  }
}

class _PipAvatarFallback extends StatelessWidget {
  const _PipAvatarFallback({
    required this.user,
    required this.userId,
    required this.background,
  });

  final database.User? user;
  final String userId;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        final double size =
            (math.min(constraints.maxWidth, constraints.maxHeight) * 0.56)
                .clamp(32.0, 64.0);
        return ColoredBox(
          color: background,
          child: Center(
            child: user != null
                ? FluxerAvatar.fromUserRow(user!, size: size, showStatus: false)
                : FluxerAvatar.user(
                    userId: userId,
                    size: size,
                    showStatus: false,
                  ),
          ),
        );
      },
    );
  }
}

class _PipScreenShareAudio extends ConsumerStatefulWidget {
  const _PipScreenShareAudio({
    required this.streamKey,
    required this.audioTrack,
  });

  final String? streamKey;
  final AudioTrack audioTrack;

  @override
  ConsumerState<_PipScreenShareAudio> createState() =>
      _PipScreenShareAudioState();
}

class _PipScreenShareAudioState extends ConsumerState<_PipScreenShareAudio> {
  AudioTrack? _currentTrack;
  var _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _syncPlayback();
  }

  @override
  void didUpdateWidget(covariant _PipScreenShareAudio oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.audioTrack != widget.audioTrack ||
        oldWidget.streamKey != widget.streamKey) {
      _syncPlayback();
      return;
    }
    unawaited(_applyVolume());
  }

  @override
  void dispose() {
    _stopTrack();
    super.dispose();
  }

  bool get _isPlaybackEnabled {
    final String? streamKey = widget.streamKey;
    if (streamKey == null) {
      return true;
    }
    return !ref.read(voiceStreamAudioProvider).isMuted(streamKey);
  }

  void _syncPlayback() {
    if (_isPlaybackEnabled) {
      _startTrack(widget.audioTrack);
      return;
    }
    _stopTrack();
  }

  Future<void> _applyVolume() async {
    final AudioTrack? track = _currentTrack;
    if (track == null || !_isPlaying) {
      return;
    }
    final String? streamKey = widget.streamKey;
    final int outputVolume = ref.read(voiceSettingsProvider).outputVolume;
    final int streamVolume = streamKey == null
        ? kDefaultVoiceVolumePercent
        : ref.read(voiceStreamAudioProvider).volumeFor(streamKey);
    await applyStreamVolumeToTrack(
      track: track,
      streamVolumePercent: streamVolume,
      outputVolumePercent: outputVolume,
    );
  }

  void _startTrack(AudioTrack track) {
    if (_currentTrack == track && _isPlaying) {
      unawaited(_applyVolume());
      return;
    }
    _stopTrack();
    _currentTrack = track;
    _isPlaying = true;
    unawaited(() async {
      await track.start();
      if (!mounted || _currentTrack != track) {
        return;
      }
      await _applyVolume();
    }());
  }

  void _stopTrack() {
    final AudioTrack? track = _currentTrack;
    _currentTrack = null;
    _isPlaying = false;
    if (track != null) {
      unawaited(track.stop());
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(voiceStreamAudioProvider);
    return const SizedBox.shrink();
  }
}
