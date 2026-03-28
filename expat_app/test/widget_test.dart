import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:expat_app/main.dart';

import 'firebase_test_setup.dart';

void main() {
  setUpAll(() async {
    await ensureFirebaseForTests();
  });

  testWidgets('ExpatApp builds (MaterialApp + entry after Firebase mock)',
      (WidgetTester tester) async {
    await tester.pumpWidget(const ExpatApp());
    await tester.pump();
    expect(find.byType(MaterialApp), findsOneWidget);
    await tester.pump(const Duration(seconds: 1));
    expect(tester.takeException(), isNull);
  });
}
