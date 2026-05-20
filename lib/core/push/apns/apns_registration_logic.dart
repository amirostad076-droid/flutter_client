/// Pure helpers for APNs mobile-device registration decisions.
bool shouldSkipApnsRegistration({
  required String currentUserId,
  required String tokenHex,
  required String? lastRegisteredUserId,
  required String? lastRegisteredTokenHex,
}) {
  if (lastRegisteredUserId != currentUserId) {
    return false;
  }
  if (lastRegisteredTokenHex == null || lastRegisteredTokenHex.isEmpty) {
    return false;
  }
  return lastRegisteredTokenHex == tokenHex;
}
