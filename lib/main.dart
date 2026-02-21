import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:fluxeron/app.dart';
import 'package:fluxeron/core/providers/app_startup_provider.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final container = ProviderContainer()..read(appStartupProvider);

  runApp(
    UncontrolledProviderScope(container: container, child: const FluxeronApp()),
  );
}
