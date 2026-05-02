import 'package:fluxer_app/features/guilds/domain/guild.dart';

String getStickerUrl({
  required String id,
  bool animated = false,
  int size = 320,
}) {
  final safeSize = size == 320 ? 320 : 160;
  final params = <String>['size=$safeSize'];
  if (animated) {
    params.add('animated=true');
  }
  return '$fluxerMediaCdn/stickers/$id.webp?${params.join('&')}';
}
