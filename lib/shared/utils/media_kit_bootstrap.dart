import 'package:media_kit/media_kit.dart';

class MediaKitBootstrap {
  MediaKitBootstrap._();

  static Future<void> ensureInitialized() async {
    return MediaKit.ensureInitialized();
  }
}
