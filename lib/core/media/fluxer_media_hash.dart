bool isAnimatedMediaHash(String hash) => hash.startsWith('a_');

String normalizeMediaHash(String hash) {
  return isAnimatedMediaHash(hash) ? hash.substring(2) : hash;
}
