import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:fluxeron/app.dart';

void main() {
  testWidgets('Login screen renders correctly', (tester) async {
    await tester.pumpWidget(const ProviderScope(child: FluxeronApp()));
    await tester.pumpAndSettle();

    expect(find.text('Welcome back!'), findsOneWidget);
    expect(find.text("We're so excited to see you again!"), findsOneWidget);
    expect(find.text('Log In'), findsOneWidget);

    // Replace the widget tree and pump once to ensure a clean teardown.
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump(const Duration(milliseconds: 100));
  });
}
