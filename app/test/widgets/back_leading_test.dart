import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/widgets/back_leading.dart';

void main() {
  group('widgets/back_leading', () {
    testInit();
    testOnPressed();
  });
}

void testInit() {
  testWidgets('init', (WidgetTester tester) async {
    await _pumpBackLeading(tester);

    final iconFinder = find.descendant(of: find.byType(BackLeading), matching: find.byType(Icon));
    final Icon icon = tester.widget<Icon>(iconFinder);

    expect(icon.icon, equals(Icons.home));
  });
}

void testOnPressed() {
  testWidgets('onPressed', (WidgetTester tester) async {
    int counter = 0;
    
    await _pumpBackLeading(tester, onPressed: () {
      counter++;
    });

    await tester.tap(find.byType(BackLeading));

    expect(counter, equals(1));

    await tester.tap(find.byType(BackLeading));
    await tester.tap(find.byType(BackLeading));
    expect(counter, equals(3));    
  });
  testWidgets('onPressed-no function set in', (WidgetTester tester) async {
    await _pumpBackLeading(tester);

    await tester.tap(find.byType(BackLeading));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _pumpBackLeading(WidgetTester tester, {VoidCallback? onPressed}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(body: BackLeading(onPressed: onPressed))
    )
  );
}