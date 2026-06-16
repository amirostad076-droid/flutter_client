/// Stable identity + cache key for a message author's avatar: author id plus
/// avatar hash, never the message id, so the image is cached once per author
/// and survives the optimistic->delivered id swap without re-fetching.
String messageAuthorAvatarKey({
  required String authorId,
  required String? avatarHash,
}) => 'msg-avatar-$authorId-${avatarHash ?? ''}';
