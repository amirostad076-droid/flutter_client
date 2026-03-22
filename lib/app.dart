import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxeron/core/router/fluxer_router.dart';
import 'package:fluxeron/l10n/generated/fluxer_localizations.dart';
import 'package:fluxeron/core/theme/fluxer_theme.dart';
import 'package:fluxeron/core/theme/fluxer_theme_mode.dart';
import 'package:fluxeron/core/theme/providers/theme_preference_provider.dart';
import 'package:fluxeron/shared/widgets/native_titlebar.dart';
import 'package:window_manager/window_manager.dart';

bool get _isDesktopPlatform =>
    !kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows);

class FluxeronApp extends ConsumerWidget {
  const FluxeronApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(fluxerRouterProvider);
    final themePref = ref.watch(themePreferenceProvider);

    return MaterialApp.router(
      title: 'Fluxer',
      debugShowCheckedModeBanner: false,
      localizationsDelegates: FluxerLocalizations.localizationsDelegates,
      supportedLocales: FluxerLocalizations.supportedLocales,
      theme: buildFluxerTheme(
        colorTheme: themePref.colorTheme,
        textTheme: themePref.textTheme,
        layoutTheme: themePref.layoutTheme,
        brightness: themePref.mode == FluxerThemeMode.light
            ? Brightness.light
            : Brightness.dark,
      ),
      routerConfig: router,
      builder: (context, child) {
        if (!_isDesktopPlatform) {
          return child!;
        }
        return DragToResizeArea(
          child: Column(
            children: [
              const NativeTitlebar(),
              Expanded(child: child!),
            ],
          ),
        );
      },
    );
  }
}
