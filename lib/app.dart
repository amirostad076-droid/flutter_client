import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/core/providers/layout_mode_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';

/// The root app widget using [MaterialApp.router] with go_router.
class FluxeronApp extends ConsumerWidget {
  const FluxeronApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(fluxerRouterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = layoutModeOf(constraints.maxWidth);
        final currentMode = ref.read(layoutModeNotifierProvider);
        if (currentMode != mode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(layoutModeNotifierProvider.notifier).setMode(mode);
          });
        }

        return MaterialApp.router(
          title: 'Fluxeron',
          debugShowCheckedModeBanner: false,
          theme: buildFluxerTheme(),
          routerConfig: router,
        );
      },
    );
  }
}
