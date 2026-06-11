const String favoriteDmGuildId = '@me';

String? resolveFavoriteGuildId({
  required String? channelGuildId,
  required bool isDm,
}) {
  if (channelGuildId != null && channelGuildId.isNotEmpty) {
    return channelGuildId;
  }
  if (isDm) {
    return favoriteDmGuildId;
  }
  return null;
}
