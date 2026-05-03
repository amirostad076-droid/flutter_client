import 'package:fluxer_app/features/channels/domain/channel.dart';

/// Snapshot of the metadata rendered above a mention card: channel name,
/// optional guild line, channel-type icon hint, and the rounded server-icon
/// avatar inputs.
class MentionHeader {
  const MentionHeader({
    required this.primary,
    required this.secondaryLine,
    required this.guildChannelVisualType,
    required this.isDm,
    required this.guildIconUrl,
    required this.guildAbbrev,
    required this.isGuildUnavailable,
  });

  factory MentionHeader.dm({required String title, required String abbrev}) {
    return MentionHeader(
      primary: title,
      secondaryLine: '',
      guildChannelVisualType: ChannelType.text,
      isDm: true,
      guildIconUrl: null,
      guildAbbrev: abbrev,
      isGuildUnavailable: false,
    );
  }

  factory MentionHeader.guild({
    required String primary,
    required ChannelType visual,
    required String secondaryLine,
    required String abbrev,
    required bool isUnavailable,
    String? iconUrl,
  }) {
    return MentionHeader(
      primary: primary,
      secondaryLine: secondaryLine,
      guildChannelVisualType: visual,
      isDm: false,
      guildIconUrl: iconUrl,
      guildAbbrev: abbrev,
      isGuildUnavailable: isUnavailable,
    );
  }

  final String primary;
  final String secondaryLine;
  final ChannelType guildChannelVisualType;
  final bool isDm;
  final String? guildIconUrl;
  final String guildAbbrev;
  final bool isGuildUnavailable;
}

/// Result returned by header loaders: the [header] for rendering and the guild
/// id used to resolve role colors in the inline preview (empty string for DMs).
class MentionHeaderResult {
  const MentionHeaderResult({
    required this.header,
    required this.guildIdForPreview,
  });

  final MentionHeader header;
  final String guildIdForPreview;
}
