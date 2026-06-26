import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/app.dart';
import 'package:fluxer_app/core/bootstrap/flutter_error_ui.dart';
import 'package:fluxer_app/core/bootstrap/image_cache_config.dart';
import 'package:fluxer_app/core/build/app_build_config.dart';
import 'package:fluxer_app/core/build/push_provider_assert.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/measure/measure_reporting_provider.dart';
import 'package:fluxer_app/core/providers/app_startup_provider.dart';
import 'package:fluxer_app/core/providers/database_provider.dart';
import 'package:fluxer_app/core/push/fcm/fcm_entrypoint.dart';
import 'package:fluxer_app/core/push/services/unified_push_service.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:measure_flutter/measure_flutter.dart';
import 'package:window_manager/window_manager.dart';

void _configureImagePicker() {
  if (kIsWeb || !Platform.isAndroid) {
    return;
  }
  final ImagePickerPlatform implementation = ImagePickerPlatform.instance;
  if (implementation is ImagePickerAndroid) {
    implementation.useAndroidPhotoPicker = true;
  }
}

bool _shouldInitializeMeasure() {
  if (kIsWeb) {
    return false;
  }
  return (Platform.isAndroid || Platform.isIOS) &&
      AppBuildConfig.hasMeasureConfig;
}

void _runFluxerApp(ProviderContainer container) {
  final Widget app = UncontrolledProviderScope(
    container: container,
    child: const FluxerApp(),
  );
  if (_shouldInitializeMeasure()) {
    runApp(MeasureWidget(child: app));
    return;
  }
  runApp(app);
}

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  configureFluxerImageCache();
  configureFluxerErrorUi();
  assertPushProviderBuildConfig();
  await bootstrapFcmIfNeeded();
  _configureImagePicker();
  final bool isUnifiedPushBackground =
      args.contains('--unifiedpush-bg') &&
      Platform.isAndroid &&
      PushProviderGuard.isUnifiedPush;
  if (isUnifiedPushBackground) {
    await UnifiedPushService.ensureBackgroundInitialized();
    return;
  }

  if (!kIsWeb && (Platform.isLinux || Platform.isMacOS || Platform.isWindows)) {
    await windowManager.ensureInitialized();

    const windowOptions = WindowOptions(
      size: Size(1280, 720),
      minimumSize: Size(200, 200),
      center: true,
      titleBarStyle: TitleBarStyle.hidden,
      title: 'Fluxer',
    );

    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  final ProviderContainer container = ProviderContainer();
  if (PushProviderGuard.isUnifiedPush) {
    UnifiedPushService.instance.attachDatabase(
      container.read(fluxerDatabaseProvider),
    );
  }
  container.read(appStartupProvider);

  if (_shouldInitializeMeasure()) {
    await Measure.instance.init(
      () async {
        await container.read(measureReportingProvider.notifier).load();
        _runFluxerApp(container);
      },
      config: MeasureConfig(
        autoStart: false,
        enableLogging: kDebugMode,
      ),
    );
    return;
  }
  _runFluxerApp(container);
}
