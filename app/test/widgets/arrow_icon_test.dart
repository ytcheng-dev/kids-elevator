import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/models/enums.dart';

import 'package:elevator/styles/layout_css.dart';

import 'package:elevator/widgets/arrow_icon.dart';

void main() {
  group('widgets/arrow_icon', () {
    testInit();
  });
}

void testInit() {
  testWidgets('init ScreenIcon: up', (WidgetTester tester) async {
    await _pumpArrowIcon(tester, ScreenIcon.up);

    Icon icon = _getIcon(tester);

    IconData? iconData = icon.icon;
    Color? color = icon.color;

    expect(iconData, equals(Icons.arrow_upward));
    expect(color, equals(LayoutCss.primary));
  });

  testWidgets('init ScreenIcon: down', (WidgetTester tester) async {
    await _pumpArrowIcon(tester, ScreenIcon.down);

    Icon icon = _getIcon(tester);

    IconData? iconData = icon.icon;
    Color? color = icon.color;

    expect(iconData, equals(Icons.arrow_downward));
    expect(color, equals(LayoutCss.primary));
  });

  testWidgets('init ScreenIcon: left', (WidgetTester tester) async {
    await _pumpArrowIcon(tester, ScreenIcon.left);

    Icon icon = _getIcon(tester);

    IconData? iconData = icon.icon;
    Color? color = icon.color;

    expect(iconData, equals(Icons.chevron_left));
    expect(color, equals(LayoutCss.secondary));
  });

  testWidgets('init ScreenIcon: right', (WidgetTester tester) async {
    await _pumpArrowIcon(tester, ScreenIcon.right);

    Icon icon = _getIcon(tester);

    IconData? iconData = icon.icon;
    Color? color = icon.color;

    expect(iconData, equals(Icons.chevron_right));
    expect(color, equals(LayoutCss.secondary));
  });
}

Future<void> _pumpArrowIcon(WidgetTester tester, ScreenIcon directionIcon) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ArrowIcon(directionIcon: directionIcon)
      )
    )
  );
}

Icon _getIcon(WidgetTester tester) {
  final iconFinder = find.descendant(
    of: find.byType(ArrowIcon), 
    matching: find.byType(Icon)
  );

  return tester.widget<Icon>(iconFinder);
}