import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_markdown/fluxer_markdown.dart';

class _RealHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    HttpOverrides.global = null;
    final client = HttpClient(context: context);
    HttpOverrides.global = this;
    return client;
  }
}

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  setUp(() {
    HttpOverrides.global = _RealHttpOverrides();
  });

  tearDown(() {
    HttpOverrides.global = null;
  });

  test('loads the red heart SVG from the static CDN', () async {
    final tempDir = await Directory.systemTemp.createTemp('emoji_cache_real');
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'getTemporaryDirectory') {
            return tempDir.path;
          }
          return null;
        });
    await EmojiAssetCache.clearCacheForTesting();

    final bytes = await EmojiAssetCache.loadBytes(
      'https://fluxerstatic.com/emoji/2764.svg?v=2',
    );
    final svg = String.fromCharCodes(bytes);
    expect(svg, contains('<svg'));

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
    await tempDir.delete(recursive: true);
  });
}
