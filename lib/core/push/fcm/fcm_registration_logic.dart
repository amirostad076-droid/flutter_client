bool shouldSkipFcmRegistration({
  required String currentUserId,
  required String token,
  required String? lastRegisteredUserId,
  required String? lastRegisteredToken,
}) {
  if (lastRegisteredUserId != currentUserId) {
    return false;
  }
  if (lastRegisteredToken == null || lastRegisteredToken.isEmpty) {
    return false;
  }
  return lastRegisteredToken == token;
}
