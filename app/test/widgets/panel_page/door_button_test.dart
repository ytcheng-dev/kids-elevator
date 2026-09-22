import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/widgets/panel_page/door_button.dart';

import 'package:elevator/models/enums.dart';
import 'package:elevator/models/panel_buttons.dart';

import 'package:elevator/styles/layout_css.dart';

const Color _shadowColor = LayoutCss.neutral2,
            _highlightColor = LayoutCss.secondary5,
            _defaultTestColor = LayoutCss.text1;

final Border _shadowBorder = Border.all(color: _shadowColor),
             _highlightBorder = Border.all(color: _highlightColor);

const BoxShadow _onPressedShadow = BoxShadow(color: _shadowColor, offset: Offset(0,1), blurRadius: 0),
                _notPressedShadow = BoxShadow(color: _shadowColor, offset: Offset(0,5), blurRadius: 0);

const Duration longPressTimeout = Duration(milliseconds: 500 + 100);
void main() {
  group('widgets/panel_page/door_button', () {
    testInit();
    testOnTap();
    testOnLongPressStart();
    testOnLongPressEnd();
    testOnPointer();
  });
}

void testInit() {
  group('init: ', () {
    testWidgets('btnType = open', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.open);

      final Icon icon = _getIcon(tester);

      expect(icon.icon, Icons.unfold_more_outlined);

      final decoration = _getContainerDecoration(tester);

      expect(decoration.color, LayoutCss.secondary0);
      expect(decoration.border, equals(_shadowBorder));
      expect(decoration.boxShadow!.first, equals(_notPressedShadow));
      expect(icon.color, equals(_defaultTestColor));
    });

    testWidgets('btnType = close', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.close);

      final Icon icon = _getIcon(tester);

      expect(icon.icon, Icons.unfold_less_outlined);

      final decoration = _getContainerDecoration(tester);

      expect(decoration.color, LayoutCss.secondary0);
      expect(decoration.border, equals(_shadowBorder));
      expect(decoration.boxShadow!.first, equals(_notPressedShadow));
      expect(icon.color, equals(_defaultTestColor));
    });
  });
}

void testOnTap() {
  group('onTap: ', () {
    testWidgets('default', (WidgetTester tester) async {
      int counter = 0;
      await _pumpDoorButton(tester, ActionType.open, onTap: () {
        counter++;
      });

      await tester.tap(find.byType(DoorButton));

      expect(counter, equals(1));

      await tester.tap(find.byType(DoorButton));
      await tester.tap(find.byType(DoorButton));
      expect(counter, equals(3));
    });

     testWidgets('no function set in', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.open);

      await tester.tap(find.byType(DoorButton));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  }); 
}

void testOnLongPressStart() {
  group('onLongPressStart: ', () {
    testWidgets('default', (WidgetTester tester) async {
      bool checkLongPressStart = false;

      await _pumpDoorButton(tester, ActionType.open, onLongPressStart: () {
        checkLongPressStart = true;
      });

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump(longPressTimeout);

      expect(checkLongPressStart, isTrue);

      await gesture.up();
    });
    testWidgets('quick tap', (WidgetTester tester) async {
      bool checkLongPressStart = false;

      await _pumpDoorButton(tester, ActionType.open, onLongPressStart: () {
        checkLongPressStart = true;
      });

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump();

      expect(checkLongPressStart, isFalse);

      await gesture.up();
    });

    testWidgets('no function set in', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.open);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump(longPressTimeout);

      await gesture.up();

      expect(tester.takeException(), isNull);
    });
  });
}

void testOnLongPressEnd() {
  group('onLongPressEnd: ', () {
    testWidgets('default', (WidgetTester tester) async {
      bool checkLongPressEnd = false;

      await _pumpDoorButton(tester, ActionType.open, onLongPressEnd: () {
        checkLongPressEnd = true;
      });

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump(longPressTimeout);

      expect(checkLongPressEnd, isFalse);

      await gesture.up();
      await tester.pump();

      expect(checkLongPressEnd, isTrue);
    });

    testWidgets('quick tap', (WidgetTester tester) async {
      bool checkLongPressEnd = false;

      await _pumpDoorButton(tester, ActionType.open, onLongPressEnd: () {
        checkLongPressEnd = true;
      });

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump();

      expect(checkLongPressEnd, isFalse);

      await gesture.up();
      await tester.pump();

      expect(checkLongPressEnd, isFalse);
    });

    testWidgets('no function set in', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.open);

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump(longPressTimeout);

      await gesture.up();

      expect(tester.takeException(), isNull);
    });
  });
}

void testOnPointer() {
  group('onPointer: ', () {
    testWidgets('down then up', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.open);

      final initDecoration = _getContainerDecoration(tester);
      final initIcon = _getIcon(tester);

      expect(initDecoration.color, LayoutCss.secondary0);
      expect(initDecoration.border, equals(_shadowBorder));
      expect(initDecoration.boxShadow!.first, equals(_notPressedShadow));
      expect(initIcon.color, equals(_defaultTestColor));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump();

      final pointerDecoration = _getContainerDecoration(tester);
      final pointerIcon = _getIcon(tester);

      expect(pointerDecoration.color, LayoutCss.secondary2);
      expect(pointerDecoration.border, equals(_highlightBorder));
      expect(pointerDecoration.boxShadow!.first, equals(_onPressedShadow));
      expect(pointerIcon.color, equals(_highlightColor));

      await gesture.up();
      await tester.pump();

      final upDecoration = _getContainerDecoration(tester);
      final upIcon = _getIcon(tester);

      expect(upDecoration.color, LayoutCss.secondary0);
      expect(upDecoration.border, equals(_shadowBorder));
      expect(upDecoration.boxShadow!.first, equals(_notPressedShadow));
      expect(upIcon.color, equals(_defaultTestColor));
    });

    testWidgets('down then cancel', (WidgetTester tester) async {
      await _pumpDoorButton(tester, ActionType.open);

      final initDecoration = _getContainerDecoration(tester);
      final initIcon = _getIcon(tester);

      expect(initDecoration.color, LayoutCss.secondary0);
      expect(initDecoration.border, equals(_shadowBorder));
      expect(initDecoration.boxShadow!.first, equals(_notPressedShadow));
      expect(initIcon.color, equals(_defaultTestColor));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(DoorButton))
      );
      await tester.pump();

      final pointerDecoration = _getContainerDecoration(tester);
      final pointerIcon = _getIcon(tester);

      expect(pointerDecoration.color, LayoutCss.secondary2);
      expect(pointerDecoration.border, equals(_highlightBorder));
      expect(pointerDecoration.boxShadow!.first, equals(_onPressedShadow));
      expect(pointerIcon.color, equals(_highlightColor));

      await gesture.cancel();
      await tester.pump();

      final cancelDecoration = _getContainerDecoration(tester);
      final cancelIcon = _getIcon(tester);

      expect(cancelDecoration.color, LayoutCss.secondary0);
      expect(cancelDecoration.border, equals(_shadowBorder));
      expect(cancelDecoration.boxShadow!.first, equals(_notPressedShadow));
      expect(cancelIcon.color, equals(_defaultTestColor));
    });
  });
}

Future<void> _pumpDoorButton(WidgetTester tester, ActionType btnType, {VoidCallback? onTap, VoidCallback? onLongPressStart, VoidCallback? onLongPressEnd}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: DoorButton(
          actionButton: ActionButton(
                            title: 'Tester', 
                            btnType: btnType, 
                            audioFile: 'testerAudio'
                          ),
          onTap: onTap,
          onLongPressStart: onLongPressStart,
          onLongPressEnd: onLongPressEnd
        )
      )
    )
  );
}

BoxDecoration _getContainerDecoration(WidgetTester tester) {
  final containerFinder = find.descendant(of: find.byType(DoorButton), matching: find.byType(Container));
  final Container container = tester.widget<Container>(containerFinder);

  return container.decoration as BoxDecoration;
}

Icon _getIcon(WidgetTester tester) {
  final iconFinder = find.descendant(of: find.byType(DoorButton), matching: find.byType(Icon));

  return tester.widget<Icon>(iconFinder);
}