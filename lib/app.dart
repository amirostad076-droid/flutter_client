import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/providers/layout_mode_provider.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/shared/widgets/responsive_layout.dart';
import 'package:fluxeron/shared/widgets/window_title_bar.dart';
import 'package:window_manager/window_manager.dart';

bool get _isDesktopPlatform =>
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

/// The root app widget using [MaterialApp.router] with go_router.
class FluxeronApp extends ConsumerWidget {
  const FluxeronApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(fluxerRouterProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final mode = layoutModeOf(constraints.maxWidth);
        final currentMode = ref.read(layoutModeProvider);
        if (currentMode != mode) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            ref.read(layoutModeProvider.notifier).setMode(mode);
          });
        }

        return MaterialApp.router(
          title: 'Fluxer',
          debugShowCheckedModeBanner: false,
          theme: buildFluxerTheme(),
          routerConfig: router,
          builder: (context, child) {
            if (!_isDesktopPlatform) {
              return child!;
            }
            return DragToResizeArea(
              child: Column(
                children: [
                  const WindowTitleBar(),
                  Expanded(child: child!),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
