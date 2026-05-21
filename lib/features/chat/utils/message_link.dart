String channelLink(String channelId, String? guildId) {
  final scope = guildId == null || guildId.isEmpty ? '@me' : guildId;
  return 'https://fluxer.app/channels/$scope/$channelId';
}

String messageLink({
  required String channelId,
  required String messageId,
  required String? guildId,
}) {
  return '${channelLink(channelId, guildId)}/$messageId';
}
