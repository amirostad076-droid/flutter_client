import 'package:fluxer_app/features/guilds/domain/guild.dart'
    show fluxerMediaCdn;

String? buildUserAvatarUrl({
  required String userId,
  required String? avatarHash,
}) {
  if (avatarHash == null || avatarHash.isEmpty) {
    return null;
  }
  return '$fluxerMediaCdn/avatars/$userId/$avatarHash.png';
}
