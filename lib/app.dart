import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';

/// The root app widget using [MaterialApp.router] with go_router.
class FluxeronApp extends ConsumerWidget {
  const FluxeronApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(fluxerRouterProvider);

    return MaterialApp.router(
      title: 'Fluxeron',
      debugShowCheckedModeBanner: false,
      theme: buildFluxerTheme(),
      routerConfig: router,
    );
  }
}
