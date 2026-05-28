import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/widgets.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluxer_app/shared/utils/emoji_utils.dart';

class TwemojiSvgCache {
  TwemojiSvgCache._();

  static final Map<String, Future<Uint8List>> _cache =
      <String, Future<Uint8List>>{};

  static Future<Uint8List> load(String url) {
    return _cache.putIfAbsent(url, () async {
      final uri = Uri.parse(url);
      final response = await HttpClient().getUrl(uri).then((r) => r.close());
      final builder = BytesBuilder();
      await response.forEach(builder.add);
      return builder.toBytes();
    });
  }
}

class UnicodeEmojiWidget extends StatelessWidget {
  const UnicodeEmojiWidget({
    required this.emoji,
    required this.size,
    super.key,
  });

  final String emoji;
  final double size;

  @override
  Widget build(BuildContext context) {
    final unicode = resolveUnicodeEmoji(emoji);
    final url = getTwemojiUrl(unicode);
    if (url == null) {
      return Text(unicode, style: TextStyle(fontSize: size));
    }
    return SizedBox(
      width: size,
      height: size,
      child: FutureBuilder<Uint8List>(
        future: TwemojiSvgCache.load(url),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const SizedBox.shrink();
          }
          return SvgPicture.memory(snapshot.data!, width: size, height: size);
        },
      ),
    );
  }
}
