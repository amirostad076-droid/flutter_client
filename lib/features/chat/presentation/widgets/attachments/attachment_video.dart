import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_thumbhash/flutter_thumbhash.dart';
import 'package:fluxer_app/core/theme/fluxer_theme_extension.dart';
import 'package:fluxer_app/features/chat/domain/message.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/attachments/attachment_mobile_video.dart';
import 'package:fluxer_app/features/chat/utils/attachment_display_utils.dart';
import 'package:fluxer_app/features/chat/utils/media_dimension_utils.dart';
import 'package:fluxer_app/features/settings/providers/chat_preferences_provider.dart';
import 'package:fluxer_app/features/shell/presentation/responsive_layout.dart';
import 'package:fluxer_app/features/ui/spinner/fluxer_loading_spinner.dart';
import 'package:fluxer_app/shared/external_links/external_link_handler.dart';
import 'package:fluxer_app/shared/widgets/shared_video_controls.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart' as mkv;

typedef AttachmentVideoControlsBuilder = Widget Function(mkv.VideoState state);

class AttachmentVideo extends StatefulWidget {
  const AttachmentVideo({
    required this.attachment,
    this.dimensionSize = MediaDimensionSize.small,
    this.controlsBuilder,
    super.key,
  });

  final Attachment attachment;
  final MediaDimensionSize dimensionSize;
  final AttachmentVideoControlsBuilder? controlsBuilder;

  @override
  State<AttachmentVideo> createState() => _AttachmentVideoState();
}

class _AttachmentVideoState extends State<AttachmentVideo> {
  static const double _defaultAspectRatio = 16 / 9;

  Player? _player;
  mkv.VideoController? _controller;
  StreamSubscription<bool>? _playingSubscription;
  StreamSubscription<bool>? _bufferingSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  StreamSubscription<Duration>? _durationSubscription;
  bool _isPlaying = false;
  bool _isBuffering = false;
  bool _isLoading = false;
  bool _hasLoadedMedia = false;
  bool _showControls = true;
  Duration _position = Duration.zero;
  Duration _duration = Duration.zero;
  double _volume = 1;
  bool _isMuted = false;
  double _playbackRate = 1;
  Timer? _controlsHideTimer;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _controlsHideTimer?.cancel();
    unawaited(_playingSubscription?.cancel());
    unawaited(_bufferingSubscription?.cancel());
    unawaited(_positionSubscription?.cancel());
    unawaited(_durationSubscription?.cancel());
    unawaited(_player?.dispose());
    super.dispose();
  }

  double _resolveAspectRatio() {
    final int? width = widget.attachment.width;
    final int? height = widget.attachment.height;
    if (width != null && height != null && width > 0 && height > 0) {
      return width / height;
    }
    return _defaultAspectRatio;
  }

  Future<void> _openMobileFullscreen() async {
    if (widget.attachment.url.isEmpty) {
      return;
    }
    await showAttachmentMobileFullscreenVideo(
      context,
      attachment: widget.attachment,
    );
  }

  Future<void> _startPlayback() async {
    if (_isLoading || widget.attachment.url.isEmpty) {
      return;
    }
    setState(() {
      _isLoading = true;
    });
    try {
      final Player player = _ensurePlayer();
      if (_hasLoadedMedia) {
        await player.play();
      } else {
        await player.open(Media(widget.attachment.url));
        _hasLoadedMedia = true;
      }
      if (!mounted) {
        return;
      }
      _showControlsTemporarily();
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

  @override
  Widget build(BuildContext context) {
    final bool isMobile = isMobileLayout(context);
    final FluxerMediaDimensions dimensions = mediaDimensionsForSize(
      widget.dimensionSize,
    );
    return Container(
      margin: const EdgeInsets.only(top: 4, bottom: 3),
      constraints: BoxConstraints(
        maxWidth: dimensions.maxWidth,
        maxHeight: dimensions.maxHeight,
      ),
      decoration: BoxDecoration(
        color: context.colors.backgroundSecondaryAlt,
        borderRadius: BorderRadius.circular(8),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: AspectRatio(
          aspectRatio: _resolveAspectRatio(),
          child: isMobile
              ? GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _openMobileFullscreen,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: <Widget>[
                      _buildPoster(),
                      Center(
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.6),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.play_arrow,
                            color: context.colors.textOnBrandPrimary,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              : _hasLoadedMedia
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    mkv.Video(
                      controller: _controller!,
                      controls: widget.controlsBuilder ?? _buildDefaultControls,
                    ),
                    if (_isBuffering)
                      IgnorePointer(
                        child: ColoredBox(
                          color: Colors.black.withValues(alpha: 0.22),
                          child: const Center(child: FluxerLoadingSpinner()),
                        ),
                      ),
                  ],
                )
              : GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: _startPlayback,
                  child: Stack(
                    fit: StackFit.expand,
                    alignment: Alignment.center,
                    children: [
                      _buildPoster(),
                      if (_isLoading)
                        const Center(child: FluxerLoadingSpinner())
                      else
                        Center(
                          child: Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.6),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.play_arrow,
                              color: context.colors.textOnBrandPrimary,
                              size: 28,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  Player _ensurePlayer() {
    final Player? existingPlayer = _player;
    if (existingPlayer != null) {
      return existingPlayer;
    }
    final Player player = Player();
    _player = player;
    unawaited(player.setVolume(_volume));
    unawaited(player.setRate(_playbackRate));
    _controller = mkv.VideoController(player);
    _playingSubscription = player.stream.playing.listen((bool playing) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isPlaying = playing;
      });
    });
    _bufferingSubscription = player.stream.buffering.listen((bool buffering) {
      if (!mounted) {
        return;
      }
      setState(() {
        _isBuffering = buffering;
      });
    });
    _positionSubscription = player.stream.position.listen((Duration position) {
      if (!mounted) {
        return;
      }
      setState(() {
        _position = position;
      });
    });
    _durationSubscription = player.stream.duration.listen((Duration duration) {
      if (!mounted) {
        return;
      }
      setState(() {
        _duration = duration;
      });
    });
    return player;
  }

  Widget _buildDefaultControls(mkv.VideoState state) {
    return SharedVideoControls(
      isPlaying: _isPlaying,
      showControls: _showControls,
      isMuted: _isMuted,
      volume: _volume,
      playbackRate: _playbackRate,
      positionLabel: formatAttachmentDurationMmSs(_position),
      durationLabel: formatAttachmentDurationMmSs(_duration),
      progress: _duration.inMilliseconds <= 0
          ? 0
          : (_position.inMilliseconds / _duration.inMilliseconds).clamp(0, 1),
      onShowControls: _showControlsTemporarily,
      onTogglePlayPause: _togglePlayPause,
      onToggleMute: _toggleMute,
      onVolumeChanged: _setVolume,
      onCyclePlaybackRate: _cyclePlaybackRate,
      onToggleFullscreen: _toggleFullscreen,
      onSeekFromGlobalDx: _seekFromGlobalDx,
    );
  }

  Future<void> _togglePlayPause() async {
    final Player? player = _player;
    if (player == null) {
      return;
    }
    if (_isPlaying) {
      await player.pause();
      _controlsHideTimer?.cancel();
      if (mounted) {
        setState(() {
          _showControls = true;
        });
      }
      return;
    }
    await player.play();
    _showControlsTemporarily();
  }

  Future<void> _seekFromGlobalDx(double globalDx, BuildContext context) async {
    final RenderObject? renderObject = context.findRenderObject();
    if (renderObject is! RenderBox || _duration <= Duration.zero) {
      return;
    }
    final Offset local = renderObject.globalToLocal(Offset(globalDx, 0));
    final double relative = (local.dx / renderObject.size.width).clamp(0, 1);
    final int targetMs = (_duration.inMilliseconds * relative).round();
    await _player?.seek(Duration(milliseconds: targetMs));
    _showControlsTemporarily();
  }

  Future<void> _toggleMute() async {
    _isMuted = !_isMuted;
    if (_isMuted) {
      await _player?.setVolume(0);
    } else {
      await _player?.setVolume(_volume);
    }
    if (mounted) {
      setState(() {});
    }
    _showControlsTemporarily();
  }

  Future<void> _setVolume(double value) async {
    _volume = value.clamp(0, 1);
    if (!_isMuted) {
      await _player?.setVolume(_volume);
    }
    if (mounted) {
      setState(() {});
    }
    _showControlsTemporarily();
  }

  Future<void> _cyclePlaybackRate() async {
    const List<double> rates = <double>[1, 1.25, 1.5, 2];
    final int index = rates.indexOf(_playbackRate);
    final int next = index < 0 || index == rates.length - 1 ? 0 : index + 1;
    _playbackRate = rates[next];
    await _player?.setRate(_playbackRate);
    if (mounted) {
      setState(() {});
    }
    _showControlsTemporarily();
  }

  Future<void> _toggleFullscreen() async {
    if (!mounted || _controller == null) {
      return;
    }
    await showDialog<void>(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.94),
      builder: (BuildContext dialogContext) {
        return GestureDetector(
          onTap: () => Navigator.of(dialogContext).pop(),
          child: ColoredBox(
            color: Colors.transparent,
            child: Center(
              child: AspectRatio(
                aspectRatio: _resolveAspectRatio(),
                child: mkv.Video(controller: _controller!, controls: null),
              ),
            ),
          ),
        );
      },
    );
    _showControlsTemporarily();
  }

  void _showControlsTemporarily() {
    if (!_showControls && mounted) {
      setState(() {
        _showControls = true;
      });
    }
    _controlsHideTimer?.cancel();
    if (!_isPlaying) {
      return;
    }
    _controlsHideTimer = Timer(const Duration(seconds: 2), () {
      if (!mounted || !_isPlaying) {
        return;
      }
      setState(() {
        _showControls = false;
      });
    });
  }

  Widget _buildPoster() {
    final String? placeholder = widget.attachment.placeholder;
    if (placeholder != null && placeholder.isNotEmpty) {
      return Image(
        image: ThumbHash.fromBase64(placeholder).toImage(),
        fit: BoxFit.cover,
      );
    }
    return ColoredBox(
      color: Colors.black,
      child: Center(
        child: Icon(
          Icons.videocam_rounded,
          color: Colors.white.withValues(alpha: 0.5),
          size: 38,
        ),
      ),
    );
  }
}
