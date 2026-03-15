import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/core/theme/fluxer_layout_theme.dart';
import 'package:fluxeron/core/theme/fluxer_text_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/core/theme/themes/dark.dart';
import 'package:fluxeron/shared/widgets/window_title_bar.dart';
import 'package:window_manager/window_manager.dart';

bool get _isDesktopPlatform =>
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

class FluxeronApp extends ConsumerWidget {
  const FluxeronApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(fluxerRouterProvider);

    return MaterialApp.router(
      title: 'Fluxer',
      debugShowCheckedModeBanner: false,
      theme: () {
            final colorTheme = buildDarkColorTheme();
            return buildFluxerTheme(
              colorTheme: colorTheme,
              textTheme: FluxerTextTheme.fromColors(colorTheme),
              layoutTheme: FluxerLayoutTheme.scaled(),
            );
          }(),
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
  }
}
