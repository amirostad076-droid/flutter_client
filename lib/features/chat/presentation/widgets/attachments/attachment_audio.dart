import 'dart:async';
import 'dart:ui';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/ui/ui.dart';
import 'package:fluxer_app/shared/widgets/volume_popout_control.dart';
import 'package:fluxer_app/shared/external_links/external_link_handler.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class AttachmentAudio extends StatefulWidget {
  const AttachmentAudio({required this.attachment, super.key});

  final Attachment attachment;

  @override
  State<AttachmentAudio> createState() => _AttachmentAudioState();
}

class _AttachmentAudioState extends State<AttachmentAudio> {
  AudioPlayer? _player;
  StreamSubscription<PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  bool _isPlaying = false;
  bool _isLoading = false;
  bool _hasPreparedSource = false;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1;
  bool _isMuted = false;
  double _playbackRate = 1;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    unawaited(_playerStateSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (_isLoading || widget.attachment.url.isEmpty) {
      return;
    }
    if (_isPlaying) {
      await _player?.pause();
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final AudioPlayer player = _ensurePlayer();
      if (!_hasPreparedSource) {
        await player.setSourceUrl(widget.attachment.url);
        _hasPreparedSource = true;
      }
      if (_duration > Duration.zero && _position >= _duration) {
        await player.seek(Duration.zero);
      }
      await player.resume();
    } on Object {
      if (!mounted) {
        return;
      }
      await handleExternalLinkTap(context, widget.attachment.url);
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  AudioPlayer _ensurePlayer() {
    final AudioPlayer? existingPlayer = _player;
    if (existingPlayer != null) {
      return existingPlayer;
    }
    final AudioPlayer player = AudioPlayer();
    _player = player;
    unawaited(player.setVolume(_isMuted ? 0 : _volume));
    unawaited(player.setPlaybackRate(_playbackRate));
    _playerStateSubscription = player.onPlayerStateChanged.listen((
      PlayerState playerState,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = playerState == PlayerState.playing;
        if (playerState == PlayerState.stopped) {
          _position = Duration.zero;
        }
      });
    });
    _positionSubscription = player.onPositionChanged.listen((
      Duration position,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = position;
      });
    });
    _durationSubscription = player.onDurationChanged.listen((
      Duration duration,
    ) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = duration;
      });
    });
    return player;
  }

  Future<void> _setVolume(double value) async {
    final double clamped = value.clamp(0, 1);
    setState(() {
      _volume = clamped;
      if (clamped > 0) {
        _isMuted = false;
      }
    });
    await _player?.setVolume(_isMuted ? 0 : clamped);
  }

  Future<void> _toggleMute() async {
    setState(() {
      _isMuted = !_isMuted;
    });
    await _player?.setVolume(_isMuted ? 0 : _volume);
  }

  Future<void> _cyclePlaybackRate() async {
    const List<double> rates = <double>[1, 1.25, 1.5, 2];
    final int index = rates.indexOf(_playbackRate);
    final int nextIndex = index < 0 || index == rates.length - 1
        ? 0
        : index + 1;
    final double nextRate = rates[nextIndex];
    setState(() {
      _playbackRate = nextRate;
    });
    await _player?.setPlaybackRate(nextRate);
  }

  Future<void> _downloadAudio() async {
    if (widget.attachment.url.isEmpty || !mounted) {
      return;
    }
    await handleExternalLinkTap(context, widget.attachment.url);
  }

  Future<void> _seekToRelativePosition(double relative) async {
    if (_duration <= Duration.zero) {
      return;
    }
    final double normalized = relative.clamp(0, 1);
    final int targetMilliseconds = (_duration.inMilliseconds * normalized)
        .round();
    final Duration target = Duration(milliseconds: targetMilliseconds);
    final AudioPlayer player = _ensurePlayer();
    await player.seek(target);
  }

  Future<void> _seekFromGlobalPosition({
    required double globalDx,
    required RenderBox renderBox,
  }) async {
    final Offset local = renderBox.globalToLocal(Offset(globalDx, 0));
    final double relative = local.dx / renderBox.size.width;
    await _seekToRelativePosition(relative);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final String fileName = _splitFileName(widget.attachment.filename).$1;
    final String fileExtension = _splitFileName(widget.attachment.filename).$2;
    final String metaText = _buildMetaText(
      fileSize: widget.attachment.size,
      duration: _duration,
    );
    final double progress = _duration.inMilliseconds <= 0
        ? 0
        : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0, 1);
    final String timeText =
        '${_formatDuration(_position)} / ${_formatDuration(_duration)}';
    return Container(
      constraints: const BoxConstraints(maxWidth: 400),
      margin: const EdgeInsets.only(top: 4),
      padding: const EdgeInsets.only(right: 12, left: 12, top: 12, bottom: 8),
      decoration: BoxDecoration(
        color: colors.backgroundSecondary,
        border: Border.all(color: colors.backgroundModifierAccent),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _AudioPlayButton(
                isLoading: _isLoading,
                isPlaying: _isPlaying,
                onPressed: _togglePlayback,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      text: TextSpan(
                        style: context.textStyles.bodySmall.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        children: [
                          TextSpan(text: fileName),
                          TextSpan(
                            text: fileExtension,
                            style: context.textStyles.bodySmall.copyWith(
                              color: colors.textTertiary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (metaText.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        metaText,
                        style: context.textStyles.smallText.copyWith(
                          color: colors.textTertiary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Builder(
                  builder: (BuildContext context) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTapDown: (TapDownDetails details) async {
                        final RenderObject? renderObject = context
                            .findRenderObject();
                        if (renderObject is! RenderBox) {
                          return;
                        }
                        await _seekFromGlobalPosition(
                          globalDx: details.globalPosition.dx,
                          renderBox: renderObject,
                        );
                      },
                      onHorizontalDragUpdate:
                          (DragUpdateDetails details) async {
                            final RenderObject? renderObject = context
                                .findRenderObject();
                            if (renderObject is! RenderBox) {
                              return;
                            }
                            await _seekFromGlobalPosition(
                              globalDx: details.globalPosition.dx,
                              renderBox: renderObject,
                            );
                          },
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(99),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 4,
                          backgroundColor: colors.textTertiary.withValues(
                            alpha: 0.35,
                          ),
                          valueColor: AlwaysStoppedAnimation<Color>(
                            colors.brandPrimary,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 10),
              Text(
                timeText,
                style: context.textStyles.smallText.copyWith(
                  color: colors.textTertiary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              VolumePopoutControl(
                volume: _volume,
                isMuted: _isMuted,
                onVolumeChanged: _setVolume,
                onToggleMute: _toggleMute,
              ),
              const Spacer(),
              TextButton(
                onPressed: _cyclePlaybackRate,
                style: TextButton.styleFrom(
                  minimumSize: const Size(44, 28),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                child: Text(
                  '${_playbackRate}x',
                  style: context.textStyles.smallText.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Tooltip(
                message: 'Download',
                child: FluxerButton.circle(
                  onPressed: _downloadAudio,
                  variant: FluxerButtonVariant.ghost,
                  size: FluxerButtonSize.compact,
                  icon: PhosphorIconsRegular.downloadSimple,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AudioPlayButton extends StatelessWidget {
  const _AudioPlayButton({
    required this.isLoading,
    required this.isPlaying,
    required this.onPressed,
  });

  final bool isLoading;
  final bool isPlaying;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return FluxerButton.circle(
      onPressed: onPressed,
      variant: FluxerButtonVariant.primary,
      size: FluxerButtonSize.compact,
      isLoading: isLoading,
      icon: isPlaying ? PhosphorIconsFill.pause : PhosphorIconsFill.play,
    );
  }
}

(String, String) _splitFileName(String filename) {
  final int lastDot = filename.lastIndexOf('.');
  if (lastDot <= 0) {
    return (filename, '');
  }
  return (filename.substring(0, lastDot), filename.substring(lastDot));
}

String _buildMetaText({required int? fileSize, required Duration duration}) {
  final String? sizeLabel = _formatBytes(fileSize);
  final String durationLabel = _formatDuration(duration);
  if (sizeLabel == null) {
    if (duration == Duration.zero) {
      return '';
    }
    return durationLabel;
  }
  if (duration == Duration.zero) {
    return sizeLabel;
  }
  return '$sizeLabel · $durationLabel';
}

String _formatDuration(Duration duration) {
  final int totalSeconds = duration.inSeconds;
  final int minutes = totalSeconds ~/ 60;
  final int seconds = totalSeconds % 60;
  return '$minutes:${seconds.toString().padLeft(2, '0')}';
}

String? _formatBytes(int? bytes) {
  if (bytes == null || bytes <= 0) {
    return null;
  }
  const List<String> units = <String>['B', 'KB', 'MB', 'GB'];
  double value = bytes.toDouble();
  int unit = 0;
  while (value >= 1024 && unit < units.length - 1) {
    value /= 1024;
    unit++;
  }
  final int precision = unit == 0 || value >= 10 ? 0 : 1;
  return '${value.toStringAsFixed(precision)} ${units[unit]}';
}
