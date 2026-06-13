const String _kBearerPrefix = 'Bearer ';

String formatSessionAuthorizationHeader(String token) {
  final String trimmed = token.trim();
  if (trimmed.startsWith(_kBearerPrefix)) {
    return trimmed.substring(_kBearerPrefix.length).trim();
  }
  return trimmed;
}
