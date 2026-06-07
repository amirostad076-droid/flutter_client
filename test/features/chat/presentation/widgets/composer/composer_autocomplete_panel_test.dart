import 'package:cached_network_image_ce/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/composer/composer_autocomplete_field.dart';
import 'package:fluxer_app/features/ui/avatar/fluxer_avatar.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

Widget _app(Widget child) {
  final colorTheme = buildDarkColorTheme();
  return MaterialApp(
    localizationsDelegates: FluxerLocalizations.localizationsDelegates,
    supportedLocales: FluxerLocalizations.supportedLocales,
    theme: buildFluxerTheme(
      colorTheme: colorTheme,
      textTheme: FluxerTextTheme.fromColors(colorTheme),
      layoutTheme: FluxerLayoutTheme.scaled(),
    ),
    home: Scaffold(body: Center(child: child)),
  );
}

void main() {
  testWidgets('unicode emoji row renders the glyph and the :name: label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ComposerAutocompletePanelListTile(
          title: ':grinning:',
          isSelected: false,
          onTap: () {},
          emojiSurrogates: '\u{1F600}',
        ),
      ),
    );

    expect(find.text('\u{1F600}'), findsOneWidget);
    expect(find.text(':grinning:'), findsOneWidget);
  });

  testWidgets('custom emoji row renders a network image and the :name: label', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ComposerAutocompletePanelListTile(
          title: ':partyblob:',
          isSelected: false,
          onTap: () {},
          emojiImageUrl: 'https://cdn.example/emoji/1.webp',
        ),
      ),
    );
    await tester.pump();

    expect(find.byType(CachedNetworkImage), findsOneWidget);
    expect(find.text(':partyblob:'), findsOneWidget);
  });

  testWidgets('mention row keeps its avatar and shows no emoji preview', (
    tester,
  ) async {
    await tester.pumpWidget(
      _app(
        ComposerAutocompletePanelListTile(
          title: '@Alice',
          isSelected: false,
          onTap: () {},
          userAvatarFallbackText: 'Alice',
        ),
      ),
    );

    expect(find.byType(FluxerAvatar), findsOneWidget);
    expect(find.text('@Alice'), findsOneWidget);
    expect(find.byType(CachedNetworkImage), findsNothing);
  });
}
