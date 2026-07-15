import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:fluxer_app/core/theme/fluxer_color_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_layout_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_text_theme.dart';
import 'package:fluxer_app/core/theme/fluxer_theme.dart';
import 'package:fluxer_app/core/theme/themes/dark.dart';
import 'package:fluxer_app/features/chat/presentation/widgets/pickers/chat_expression_expandable_sheet.dart';
import 'package:fluxer_app/features/chat/utils/inline_expression_panel_layout.dart';
import 'package:fluxer_app/l10n/generated/fluxer_localizations.dart';

const Size _kMobileViewport = Size(390, 844);
const double _kAnchorHeight = 291;
const double _kDragHandleHeight = 36;
const double _kDockedContentHeight = _kAnchorHeight - _kDragHandleHeight;
const double _kTextareaHeight = 72;

void main() {
  final FluxerColorTheme colorTheme = buildDarkColorTheme();

  group('ChatExpressionExpandableSheet', () {
    testWidgets('opens at anchor height, not full screen', (tester) async {
      await _pumpSheet(tester, colorTheme: colorTheme);
      final double sheetHeight = tester
          .getSize(find.byKey(kChatExpressionSheetKey))
          .height;
      expect(sheetHeight, closeTo(_kAnchorHeight, 2));
      expect(sheetHeight, lessThan(_kMobileViewport.height * 0.5));
    });

    testWidgets('sheet anchors to bottom of chat slot below textarea', (
      tester,
    ) async {
      await _pumpSheet(tester, colorTheme: colorTheme);
      final Offset sheetTopLeft = tester.getTopLeft(
        find.byKey(kChatExpressionSheetKey),
      );
      final double sheetBottom =
          sheetTopLeft.dy +
          tester.getSize(find.byKey(kChatExpressionSheetKey)).height;
      expect(_kMobileViewport.height - sheetBottom, closeTo(0, 2));
    });

    testWidgets('handle can be dragged repeatedly after snap', (tester) async {
      await _pumpSheet(tester, colorTheme: colorTheme);
      final Finder dragTarget = find.byKey(kChatExpressionSheetDragHandleKey);
      final Finder sheet = find.byKey(kChatExpressionSheetKey);
      final double initialHeight = tester.getSize(sheet).height;
      final Offset dragStart = tester.getCenter(dragTarget);
      final TestGesture expandGesture = await tester.startGesture(dragStart);
      await expandGesture.moveBy(const Offset(0, -160));
      await tester.pump();
      expect(tester.getSize(sheet).height, greaterThan(initialHeight + 20));
      await expandGesture.up();
      await tester.pumpAndSettle();
      final double expandedHeight = tester.getSize(sheet).height;
      expect(expandedHeight, greaterThan(initialHeight + 20));
      final TestGesture collapseGesture = await tester.startGesture(dragStart);
      await collapseGesture.moveBy(const Offset(0, 160));
      await tester.pump();
      expect(tester.getSize(sheet).height, lessThan(expandedHeight - 20));
      await collapseGesture.up();
      await tester.pumpAndSettle();
      final double collapsedHeight = tester.getSize(sheet).height;
      expect(collapsedHeight, lessThan(expandedHeight - 20));
      final TestGesture secondExpandGesture = await tester.startGesture(
        dragStart,
      );
      await secondExpandGesture.moveBy(const Offset(0, -120));
      await tester.pump();
      expect(tester.getSize(sheet).height, greaterThan(collapsedHeight + 10));
      await secondExpandGesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('panel height stays within anchor and 75% screen bounds', (
      tester,
    ) async {
      await _pumpSheet(tester, colorTheme: colorTheme);
      final Finder dragTarget = find.byKey(kChatExpressionSheetDragHandleKey);
      final Finder sheet = find.byKey(kChatExpressionSheetKey);
      final double maxHeight =
          _kMobileViewport.height * kInlineExpressionPanelMaxScreenFraction;
      final TestGesture expandGesture = await tester.startGesture(
        tester.getCenter(dragTarget),
      );
      await expandGesture.moveBy(const Offset(0, -900));
      await tester.pump();
      expect(tester.getSize(sheet).height, lessThanOrEqualTo(maxHeight + 1));
      await expandGesture.up();
      await tester.pumpAndSettle();
      final TestGesture collapseGesture = await tester.startGesture(
        tester.getCenter(dragTarget),
      );
      await collapseGesture.moveBy(const Offset(0, 900));
      await tester.pump();
      expect(
        tester.getSize(sheet).height,
        greaterThanOrEqualTo(_kAnchorHeight - 1),
      );
      await collapseGesture.up();
      await tester.pumpAndSettle();
    });

    testWidgets('list pull down collapses expanded sheet to docked height', (
      tester,
    ) async {
      await _pumpSheet(tester, colorTheme: colorTheme);
      final Finder sheet = find.byKey(kChatExpressionSheetKey);
      final Finder list = find.byType(Scrollable).last;
      final double dockedHeight = tester.getSize(sheet).height;
      final Offset handleCenter = tester.getCenter(
        find.byKey(kChatExpressionSheetDragHandleKey),
      );
      final TestGesture expandGesture = await tester.startGesture(handleCenter);
      await expandGesture.moveBy(const Offset(0, -220));
      await tester.pump();
      await expandGesture.up();
      await tester.pumpAndSettle();
      final double expandedHeight = tester.getSize(sheet).height;
      expect(expandedHeight, greaterThan(dockedHeight + 40));
      final Offset listCenter = tester.getCenter(list);
      final TestGesture collapseGesture = await tester.startGesture(listCenter);
      await collapseGesture.moveBy(const Offset(0, 220));
      await tester.pump();
      await collapseGesture.up();
      await tester.pumpAndSettle();
      expect(tester.getSize(sheet).height, closeTo(dockedHeight, 4));
    });
  });
}

Future<void> _pumpSheet(
  WidgetTester tester, {
  required FluxerColorTheme colorTheme,
}) async {
  await tester.binding.setSurfaceSize(_kMobileViewport);
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        localizationsDelegates: FluxerLocalizations.localizationsDelegates,
        supportedLocales: FluxerLocalizations.supportedLocales,
        theme: buildFluxerTheme(
          colorTheme: colorTheme,
          textTheme: FluxerTextTheme.fromColors(colorTheme),
          layoutTheme: FluxerLayoutTheme.scaled(),
        ),
        home: Scaffold(
          body: SizedBox(
            height: _kMobileViewport.height,
            width: _kMobileViewport.width,
            child: Stack(
              children: <Widget>[
                const Column(
                  children: <Widget>[
                    Expanded(child: ColoredBox(color: Color(0xFF111111))),
                    SizedBox(
                      height: _kTextareaHeight,
                      child: ColoredBox(color: Color(0xFF222222)),
                    ),
                    SizedBox(height: _kAnchorHeight),
                  ],
                ),
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  child: ChatExpressionExpandableSheet(
                    collapsedHeight: _kDockedContentHeight,
                    dragHandleHeight: _kDragHandleHeight,
                    parentHeight: _kMobileViewport.height,
                    contentBuilder:
                        (
                          BuildContext context,
                          ScrollController scrollController,
                        ) {
                          return ListView(
                            controller: scrollController,
                            children: const <Widget>[
                              SizedBox(
                                height: 800,
                                child: ColoredBox(color: Color(0xFF333333)),
                              ),
                            ],
                          );
                        },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}
