import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fluxer_app/app.dart';
import 'package:fluxer_app/core/build/push_provider_guard.dart';
import 'package:fluxer_app/core/providers/app_startup_provider.dart';
import 'package:fluxer_app/core/push/services/unified_push_service.dart';
import 'package:image_picker_android/image_picker_android.dart';
import 'package:image_picker_platform_interface/image_picker_platform_interface.dart';
import 'package:media_kit/media_kit.dart';
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

Future<void> main(List<String> args) async {
  WidgetsFlutterBinding.ensureInitialized();
  _configureImagePicker();
  final bool isUnifiedPushBackground = args.contains('--unifiedpush-bg') &&
      Platform.isAndroid &&
      PushProviderGuard.isUnifiedPush;
  if (isUnifiedPushBackground) {
    await UnifiedPushService.ensureBackgroundInitialized();
    return;
  }
  MediaKit.ensureInitialized();

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

  final container = ProviderContainer()..read(appStartupProvider);

  runApp(
    UncontrolledProviderScope(container: container, child: const FluxerApp()),
  );
}
