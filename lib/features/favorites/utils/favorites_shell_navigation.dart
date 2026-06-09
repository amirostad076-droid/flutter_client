import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/core/router/fluxer_router.dart';
import 'package:fluxer_app/core/router/route_names.dart';
import 'package:fluxer_app/core/router/route_state_providers.dart';
import 'package:fluxer_app/features/shell/providers/drawer_reveal_sync_trigger_provider.dart';
import 'package:fluxer_app/features/shell/providers/reveal_side_provider.dart';

void returnToFavoritesList(WidgetRef ref) {
  final String location = ref.read(currentLocationProvider);
  if (location.startsWith('/channels/@favorites/')) {
    ref.read(fluxerRouterProvider).go(RoutePaths.favoritesBase);
  }
  ref.read(currentRevealSideProvider.notifier).set(RevealSide.left);
  ref.read(drawerRevealSyncTriggerProvider.notifier).nudge();
}

bool isFavoritesChannelRoute(String location) {
  return location.startsWith('/channels/@favorites/');
}
