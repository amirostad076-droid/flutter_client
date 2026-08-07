import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/chat_bottom_input_slot.dart';
import 'package:fluxer_app/features/chat/providers/pickers/bottom_input_slot_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/expression_panel_provider.dart';
import 'package:fluxer_app/features/chat/providers/pickers/mobile_keyboard_metrics_provider.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

Finder _keyboardSpacerFinder() {
  return find.descendant(
    of: find.byType(BottomInputSpacer),
    matching: find.byWidgetPredicate(
      (Widget widget) => widget is SizedBox && widget.height != null,
    ),
  );
}

Future<void> _pumpBottomInputSpacer(
  WidgetTester tester,
  ProviderContainer container,
) async {
  final colorTheme = buildDarkColorTheme();
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: FluxerLocalizations.localizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: const Scaffold(
          body: MediaQuery(
            data: MediaQueryData(size: Size(400, 800)),
            child: Column(
              children: <Widget>[
                Expanded(child: SizedBox()),
                BottomInputSpacer(),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  testWidgets('BottomInputSpacer reserves anchor height when panel is open', (
    tester,
  ) async {
    final ProviderContainer container = ProviderContainer();
    addTearDown(container.dispose);
    final colorTheme = buildDarkColorTheme();
    container.read(mobileKeyboardMetricsProvider.notifier)
      ..updateLayout(screenHeight: 800, isPortrait: true, isIos: true)
      ..syncViewInsets(0, safeAreaBottom: 0);
    container.read(expressionPanelProvider.notifier).open();

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: FluxerLocalizations.localizationsDelegates,
          supportedLocales: FluxerLocalizations.supportedLocales,
          theme: buildFluxerTheme(
            colorTheme: colorTheme,
            textTheme: FluxerTextTheme.fromColors(colorTheme),
            layoutTheme: FluxerLayoutTheme.scaled(),
          ),
          home: const Scaffold(
            body: MediaQuery(
              data: MediaQueryData(size: Size(400, 800)),
              child: SafeArea(
                child: Column(
                  children: <Widget>[
                    Expanded(child: ColoredBox(color: Color(0xFF111111))),
                    SizedBox(
                      height: 56,
                      child: ColoredBox(color: Color(0xFF222222)),
                    ),
                    BottomInputSpacer(),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pump();
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(BottomInputSpacer), findsOneWidget);
    final Size spacerSize = tester.getSize(
      find.descendant(
        of: find.byType(BottomInputSpacer),
        matching: find.byType(AnimatedContainer),
      ),
    );
    expect(spacerSize.height, greaterThan(200));

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 500));
  });

  testWidgets(
    'BottomInputSpacer snaps to keyboard slot height when panel is closed',
    (tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      container.read(mobileKeyboardMetricsProvider.notifier)
        ..updateLayout(screenHeight: 800, isPortrait: true, isIos: true)
        ..syncViewInsets(336, safeAreaBottom: 0);
      await _pumpBottomInputSpacer(tester, container);
      await tester.pump();

      final BottomInputSlotState slotState = container.read(
        bottomInputSlotProvider,
      );
      expect(slotState.slotHeight, 336);
      expect(
        find.descendant(
          of: find.byType(BottomInputSpacer),
          matching: find.byType(AnimatedContainer),
        ),
        findsNothing,
      );
      final Size spacerSize = tester.getSize(_keyboardSpacerFinder());
      expect(spacerSize.height, 336);

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    },
  );

  testWidgets(
    'BottomInputSpacer tracks successive keyboard heights without overshoot',
    (tester) async {
      final ProviderContainer container = ProviderContainer();
      addTearDown(container.dispose);
      final MobileKeyboardMetrics notifier = container.read(
        mobileKeyboardMetricsProvider.notifier,
      );
      notifier.updateLayout(screenHeight: 800, isPortrait: true, isIos: true);

      await _pumpBottomInputSpacer(tester, container);
      await tester.pump();

      for (final double height in <double>[300, 310, 302]) {
        notifier.syncViewInsets(height, safeAreaBottom: 0);
        await tester.pump();
        final Size spacerSize = tester.getSize(_keyboardSpacerFinder());
        expect(spacerSize.height, height);
      }

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump(const Duration(milliseconds: 500));
    },
  );
}
