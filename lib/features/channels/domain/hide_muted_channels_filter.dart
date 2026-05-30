/// Whether a channel should remain visible when "Hide Muted Channels" is on.
///
/// Only directly muted channels are hidden. Category and guild mutes do not
/// affect sidebar visibility.
bool shouldShowChannelWhenHidingMuted({
  required String channelId,
  required Set<String> mutedChannelIds,
  String? selectedChannelId,
}) {
  if (selectedChannelId != null && channelId == selectedChannelId) {
    return true;
  }
  return !mutedChannelIds.contains(channelId);
}
