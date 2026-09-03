import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:sprout/app.dart';

void main() {
  testWidgets('App builds and shows home title', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: SproutApp()),
    );
    await tester.pumpAndSettle();

    expect(find.text('Sprout · 成长记录'), findsOneWidget);
  });
}
