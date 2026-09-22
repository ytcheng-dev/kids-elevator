import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elevator/screens/panel_page.dart';

import 'package:elevator/widgets/floor_tile.dart';

void main() {
  group('panel page', () {
    testInit();
  });
  
}

void testInit() {
  testWidgets('landscape screen', (WidgetTester tester) async {
    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PanelPage())
      ));

    expect(find.byType(AppBar), findsNothing);
    expect(find.byType(FloorTile), findsNWidgets(7));

    const List<String> floorTitle = ['B2', 'B1', '1', '2', '3', '4', '5'];
    for (final title in floorTitle) {
      expect(find.byKey(ValueKey('floorTile$title')), findsOneWidget);
    }
  });

  testWidgets('portrait screen', (WidgetTester tester) async {
    tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);   // 註冊結束測試後還原

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: PanelPage())
      ));

    expect(find.byType(AppBar), findsOneWidget);
    expect(find.byType(FloorTile), findsNWidgets(7));

    const List<String> floorTitle = ['B2', 'B1', '1', '2', '3', '4', '5'];
    for (final title in floorTitle) {
      expect(find.byKey(ValueKey('floorTile$title')), findsOneWidget);
    }
  });
}