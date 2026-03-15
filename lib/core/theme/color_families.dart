import 'package:fluxeron/core/theme/color_generator.dart';

abstract final class FluxerColorFamilies {
  static const neutralDark = ColorFamily(hue: 220, saturation: 13);
  static const neutralLight = ColorFamily(hue: 220, saturation: 10);
  static const brand = ColorFamily(hue: 242, saturation: 70);
  static const link = ColorFamily(hue: 210, saturation: 100);
  static const accentPurple = ColorFamily(hue: 270, saturation: 80);
  static const statusOnline = ColorFamily(hue: 142, saturation: 76);
  static const statusIdle = ColorFamily(hue: 45, saturation: 93);
  static const statusDnd = ColorFamily(hue: 0, saturation: 84);
  static const statusOffline = ColorFamily(hue: 218, saturation: 11);
  static const statusDanger = ColorFamily(hue: 1, saturation: 77);
  static const textCode = ColorFamily(hue: 340, saturation: 50);
  static const brandIcon = ColorFamily(hue: 38, saturation: 92);
}
