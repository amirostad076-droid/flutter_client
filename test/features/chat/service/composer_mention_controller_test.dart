import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/service/composer_mention_controller.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

/// Builds a [ComposerMentionController] inside a live, themed widget tree and
/// returns it once the [TextField] using it has been pumped. The controller is
/// created once (guarded) so rebuilds keep the same instance, and the Fluxer
/// theme is supplied so inline mention chips can resolve `context.colors`.
Future<ComposerMentionController> _pumpController(WidgetTester tester) async {
  final colorTheme = buildDarkColorTheme();
  ComposerMentionController? controller;
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        localizationsDelegates: FluxerLocalizations.localizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        home: Scaffold(
          body: Consumer(
            builder: (BuildContext context, WidgetRef ref, Widget? _) {
              controller ??= ComposerMentionController(ref: ref);
              return TextField(controller: controller);
            },
          ),
        ),
      ),
    ),
  );
  addTearDown(() => controller?.dispose());
  return controller!;
}

void main() {
  testWidgets('stores the user mention display label and renders it', (
    WidgetTester tester,
  ) async {
    final ComposerMentionController controller = await _pumpController(tester);

    controller.insertUserMentionPlaceholder(
      matchStart: 0,
      matchEnd: 0,
      userId: '123',
      displayName: 'Alice',
    );
    await tester.pump();

    // The chip uses the stored label; no active-channel roster is available,
    // so reaching the live resolver would instead show a truncated id.
    expect(find.text('@Alice'), findsOneWidget);
    // The wire form always carries the canonical id, label or not.
    expect(controller.toWireText().trim(), '<@123>');
  });

  testWidgets('stores the channel mention display label and renders it', (
    WidgetTester tester,
  ) async {
    final ComposerMentionController controller = await _pumpController(tester);

    controller.insertChannelMentionPlaceholder(
      matchStart: 0,
      matchEnd: 0,
      channelId: '456',
      displayName: 'general',
    );
    await tester.pump();

    expect(find.text('#general'), findsOneWidget);
    expect(controller.toWireText().trim(), '<#456>');
  });

  testWidgets('keeps user labels aligned with ids after deleting one', (
    WidgetTester tester,
  ) async {
    final ComposerMentionController controller = await _pumpController(tester);

    controller
      ..insertUserMentionPlaceholder(
        matchStart: 0,
        matchEnd: 0,
        userId: '111',
        displayName: 'Alice',
      )
      ..insertUserMentionPlaceholder(
        matchStart: controller.text.length,
        matchEnd: controller.text.length,
        userId: '222',
        displayName: 'Bob',
      );
    await tester.pump();
    expect(find.text('@Alice'), findsOneWidget);
    expect(find.text('@Bob'), findsOneWidget);

    // Removing the trailing placeholder drops the last id and its label in
    // lockstep, so the surviving chip still resolves to its stored label.
    final String trimmed = controller.text.trimRight();
    controller.value = TextEditingValue(
      text: trimmed.substring(0, trimmed.length - 1),
      selection: const TextSelection.collapsed(offset: 0),
    );
    await tester.pump();

    expect(find.text('@Bob'), findsNothing);
    expect(find.text('@Alice'), findsOneWidget);
    expect(controller.toWireText().trim(), '<@111>');
  });
}
