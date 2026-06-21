class StoredAccount {
  final String userId;
  final String? username;
  final String? discriminator;
  final String? avatar;
  final bool isValid;
  final DateTime lastActive;
  final String? displayDomain;

  const StoredAccount({
    required this.userId,
    required this.isValid,
    required this.lastActive,
    this.username,
    this.discriminator,
    this.avatar,
    this.displayDomain,
  });

  String get displayName => username ?? userId;

  String get identifier =>
      discriminator != null ? '$displayName#$discriminator' : displayName;
}
