import 'package:fluxer_app/features/favorites/domain/resolved_favorite_entry.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

String? favoriteEntrySubtitle(
  ResolvedFavoriteEntry entry,
  FluxerLocalizations l10n,
) {
  final dm = entry.dm;
  if (dm == null) {
    return null;
  }
  if (dm.isGroup) {
    return l10n.dmGroupMemberCount(dm.memberCount);
  }
  return l10n.favoritesDirectMessageSubtitle;
}
