import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/domain/favorite_meme.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/favorite_media_picker_content.dart';
import 'package:fluxer_app/features/chat/providers/favorite_media_provider.dart';
import 'package:media_kit/media_kit.dart';
import 'package:riverpod/src/framework.dart' show Override;

void main() {
  setUpAll(MediaKit.ensureInitialized);
  testWidgets('video-like saved media tiles fit in narrow columns', (
    tester,
  ) async {
    await tester.pumpWidget(
      _buildTestApp(
        overrides: [
          favoriteMemesProvider.overrideWith(
            (ref) => Stream.value([
              _meme(
                id: '1',
                filename: 'very-long-saved-video-file-name.mp4',
                contentType: 'video/mp4',
              ),
            ]),
          ),
        ],
        child: const SizedBox(
          width: 220,
          height: 320,
          child: FavoriteMediaPickerContent(),
        ),
      ),
    );
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'video-like saved media tiles render media instead of filename fallback',
    (tester) async {
      const filename = 'animated-favorite.gif';

      await tester.pumpWidget(
        _buildTestApp(
          overrides: [
            favoriteMemesProvider.overrideWith(
              (ref) => Stream.value([
                _meme(id: '1', filename: filename, contentType: 'video/mp4'),
              ]),
            ),
          ],
          child: const SizedBox(
            width: 260,
            height: 320,
            child: FavoriteMediaPickerContent(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text(filename), findsNothing);
    },
  );
}

Widget _buildTestApp({
  required Widget child,
  List<Override> overrides = const [],
}) {
  final colorTheme = buildDarkColorTheme();
  return ProviderScope(
    overrides: overrides,
    child: MaterialApp(
      theme: buildFluxerTheme(
        colorTheme: colorTheme,
        textTheme: FluxerTextTheme.fromColors(colorTheme),
        layoutTheme: FluxerLayoutTheme.scaled(),
      ),
      home: Scaffold(body: Center(child: child)),
    ),
  );
}

FavoriteMeme _meme({
  required String id,
  required String filename,
  required String contentType,
}) => FavoriteMeme(
  id: id,
  userId: 'user-1',
  name: 'Saved video',
  altText: null,
  tags: const [],
  attachmentId: 'attachment-$id',
  filename: filename,
  contentType: contentType,
  contentHash: null,
  size: 1,
  width: 320,
  height: 180,
  duration: null,
  isGifv: false,
  url: 'https://cdn.example/$filename',
  klipySlug: null,
  tenorSlugId: null,
);
