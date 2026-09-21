import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/models/panel_buttons.dart';

import 'package:elevator/widgets/floor_tile.dart';

import 'package:elevator/styles/layout_css.dart';


const Color _highlightColor = LayoutCss.secondary5,
            _shadowColor = LayoutCss.neutral2;

void main() {
  group('widget/floor_tile test:', () {
    testInit();
    testOnTap();
    testButtonIsTarget();
    testOnPressed();
  });
}

void testInit() {
  testWidgets('init', (WidgetTester tester) async {
      const String title = 'Tester';
      final FloorButton floorButton = FloorButton(title: title, audioFile: 'testAudio');

      await _pumpFloorTile(tester, floorButton);

      expect(find.text(title), findsOneWidget);

    });
}

void testOnTap() {
  testWidgets('onTap', (WidgetTester tester) async {
      int counter = 0;

      await _pumpFloorTile(
        tester,
        FloorButton(title: 'Tester', audioFile: 'testAudio'),
        onTap: () {
          counter++;
        }
      );

      expect(counter, equals(0));

      // 點擊
      await tester.tap(find.byType(FloorTile));

      expect(counter, equals(1));

      await tester.tap(find.byType(FloorTile));
      await tester.tap(find.byType(FloorTile));

      expect(counter, equals(3));

    });

    testWidgets('onTap-no function set in', (WidgetTester tester) async {
      await _pumpFloorTile(tester, FloorButton(title: 'Tester', audioFile: 'testAudio'));

      // 點擊
      await tester.tap(find.byType(FloorTile));
      await tester.pump();

      expect(tester.takeException(), isNull);

    });
}

void testButtonIsTarget() {
  testWidgets('floorButton.isTarget = false, _isPressed = false', (WidgetTester tester) async {
    const String title = 'Tester';
    final FloorButton floorButton = FloorButton(title: title, audioFile: 'testAudio');

    await _pumpFloorTile(tester, floorButton);

    // FloorButton init 就是 isTarget = false
    expect(floorButton.isTarget, isFalse);

    final BoxDecoration decoration = _getDecoration(tester);

    final fittedBoxText = tester.widget<Text>(
      find.descendant(
        of: find.byType(FloorTile), 
        matching: find.byType(Text)
      )
    );

    expect(decoration.color, equals(LayoutCss.secondary0));
    expect(decoration.border, equals(Border.all(color: _shadowColor, width: 3)));
    expect(decoration.boxShadow!.first, equals(const BoxShadow(color: _shadowColor, offset: Offset(0, 5), blurRadius: 0)));
    expect(fittedBoxText.style, equals(const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: LayoutCss.text1)));
  });

  testWidgets('floorButton.isTarget = true, _isPressed = false', (WidgetTester tester) async {
    const String title = 'Tester';
    final FloorButton floorButton = FloorButton(title: title, audioFile: 'testAudio');
    floorButton.isTarget = true;

    await _pumpFloorTile(tester, floorButton);

    final BoxDecoration decoration = _getDecoration(tester);

    final fittedBoxText = tester.widget<Text>(
      find.descendant(
        of: find.byType(FloorTile), 
        matching: find.byType(Text)
      )
    );

    expect(decoration.color, equals(LayoutCss.secondary2));
    expect(decoration.border, equals(Border.all(color: _highlightColor, width: 3)));
    expect(decoration.boxShadow!.first, equals(const BoxShadow(color: _highlightColor, offset: Offset(0, 5), blurRadius: 0)));
    expect(fittedBoxText.style, equals(const TextStyle(fontSize: 48, fontWeight: FontWeight.bold, color: _highlightColor)));
  });
}

void testOnPressed() {
  const BoxShadow onPressedBox = BoxShadow(
                                    color: _shadowColor,
                                    offset: Offset(0,1),
                                    blurRadius: 0
                                  ),
                  notPressedBox = BoxShadow(color: _shadowColor,
                                    offset: Offset(0,5),
                                    blurRadius: 0
                                  ),
                  highlightBox = BoxShadow(
                    color: _highlightColor,
                    offset: Offset(0, 5),
                    blurRadius: 0
                  );
  testWidgets('_isPressed = true', (WidgetTester tester) async {
    await _pumpFloorTile(tester, FloorButton(title: 'Tester', audioFile: 'testAudio'));

    // 按下(不放開)
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloorTile))
    );
    await tester.pump();    // 重畫

    // 驗證 _isPressed = true
    final BoxDecoration decoration = _getDecoration(tester);

    expect(decoration.boxShadow!.first, equals(onPressedBox));

    await gesture.up();
  });

  testWidgets('_isPressed gesture up', (WidgetTester tester) async {
    await _pumpFloorTile(tester, FloorButton(title: 'Tester', audioFile: 'testAudio'));

    // 按下(不放開)
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloorTile))
    );
    await tester.pump();    // 重畫

    final BoxDecoration downDecoration = _getDecoration(tester);

    expect(downDecoration.boxShadow!.first, equals(onPressedBox));

    // 放開
    await gesture.up();
    await tester.pump();

    final BoxDecoration upDecoration = _getDecoration(tester);

    expect(upDecoration.boxShadow!.first, equals(notPressedBox));
  });

  testWidgets('_isPressed gesture cancel', (WidgetTester tester) async {
    await _pumpFloorTile(tester, FloorButton(title: 'Tester', audioFile: 'testAudio'));

    // 按下(不放開)
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloorTile))
    );
    await tester.pump();    // 重畫

    final BoxDecoration downDecoration = _getDecoration(tester);

    expect(downDecoration.boxShadow!.first, equals(onPressedBox));

    // 取消
    await gesture.cancel();
    await tester.pump();

    // 驗證 _isPressed = false
    final BoxDecoration cancelDecoration = _getDecoration(tester);

    expect(cancelDecoration.boxShadow!.first, equals(notPressedBox));
  });

  testWidgets('floorButton.isTarget = true, then no shadow change', (WidgetTester tester) async {
    final FloorButton floorButton = FloorButton(title: 'Tester', audioFile: 'testAudio');
    floorButton.isTarget = true;

    await _pumpFloorTile(tester, floorButton);

    // 按下(不放開)
    final gesture = await tester.startGesture(
      tester.getCenter(find.byType(FloorTile))
    );
    await tester.pump();    // 重畫

    final BoxDecoration downDecoration = _getDecoration(tester);

    expect(downDecoration.boxShadow!.first, equals(highlightBox));

    await gesture.up();
    await tester.pump();

    final BoxDecoration upDecoration = _getDecoration(tester);

    expect(upDecoration.boxShadow!.first, equals(highlightBox));
  });
}

Future<void> _pumpFloorTile(WidgetTester tester, FloorButton floorButton, {VoidCallback? onTap}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: FloorTile(
          floorButton: floorButton,
          onTap: onTap
        )))
  );
}

BoxDecoration _getDecoration(WidgetTester tester) {
  final containerFinder = find.descendant(
                              of: find.byType(FloorTile), 
                              matching: find.byType(Container)
                            );
                            
  final container =  tester.widget<Container>(containerFinder);

  return container.decoration as BoxDecoration;
}