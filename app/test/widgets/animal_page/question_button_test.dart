import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:elevator/widgets/animal_page/question_button.dart';

import 'package:elevator/styles/layout_css.dart';

const Color _defaultColor = LayoutCss.secondary;

final BoxBorder _defaultBorder = Border.all(color: _defaultColor, width: 3);

const BoxShadow _onPressShadow = BoxShadow(
                                    color: LayoutCss.neutral7,
                                    offset: Offset(0,1),
                                    blurRadius: 1
                                  ),
                _offPressShadow = BoxShadow(
                                    color: LayoutCss.neutral7,
                                    offset: Offset(0,5),
                                    blurRadius: 3
                                  );

void main() {
  group('widgets/animal_page/question_button', () {
    testInit();
    testOnTap();
    testOnPressed();
  });
}

void testInit() {
  group('init: ', () {
    testWidgets('default', (WidgetTester tester) async {
      await _pumpQuestionButton(tester);

      final borderDecoration = _getBorderContainerDecoration(tester);
      final iconDecoration = _getIconContainerDecoration(tester);

      expect(borderDecoration.border, equals(_defaultBorder));
      expect(borderDecoration.boxShadow!.first, equals(_offPressShadow));
      expect(iconDecoration.color, equals(_defaultColor));
    });
  });
}

void testOnTap() {
  group('onTap', () {
    testWidgets('default', (WidgetTester tester) async {
      int counter = 0;
      await _pumpQuestionButton(tester, onTap: () {
        counter++;
      });

      await tester.tap(find.byType(QuestionButton));

      expect(counter, equals(1));

      await tester.tap(find.byType(QuestionButton));
      await tester.tap(find.byType(QuestionButton));
      expect(counter, equals(3));
    });

    testWidgets('no function set in', (WidgetTester tester) async {
      await _pumpQuestionButton(tester);

      await tester.tap(find.byType(QuestionButton));
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });
}

void testOnPressed() {
  group('isPressed', () {
    testWidgets('down then up', (WidgetTester tester) async {
      await _pumpQuestionButton(tester);

      final initBorderDecoration = _getBorderContainerDecoration(tester);

      expect(initBorderDecoration.boxShadow!.first, equals(_offPressShadow));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(QuestionButton))
      );
      await tester.pump();

      final downBorderDecoration = _getBorderContainerDecoration(tester);

      expect(downBorderDecoration.boxShadow!.first, equals(_onPressShadow));

      await gesture.up();
      await tester.pump();

      final upBorderDecoration = _getBorderContainerDecoration(tester);

      expect(upBorderDecoration.boxShadow!.first, equals(_offPressShadow));
    });

    testWidgets('down then cancel', (WidgetTester tester) async {
      await _pumpQuestionButton(tester);

      final initBorderDecoration = _getBorderContainerDecoration(tester);

      expect(initBorderDecoration.boxShadow!.first, equals(_offPressShadow));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byType(QuestionButton))
      );
      await tester.pump();

      final downBorderDecoration = _getBorderContainerDecoration(tester);

      expect(downBorderDecoration.boxShadow!.first, equals(_onPressShadow));

      await gesture.cancel();
      await tester.pump();

      final cancelBorderDecoration = _getBorderContainerDecoration(tester);

      expect(cancelBorderDecoration.boxShadow!.first, equals(_offPressShadow));
    });
  });
}

Future<void> _pumpQuestionButton(WidgetTester tester, {bool? isShining, VoidCallback? onTap}) {
  const String imgFile = 'assets/images/animal_page/dinosaur_headshot.png';

  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: isShining == null ?
        QuestionButton(animalImg: imgFile, onTap: onTap) :
        QuestionButton(animalImg: imgFile, onTap: onTap, isShining: isShining)
      )
    )
  );
}

BoxDecoration _getBorderContainerDecoration(WidgetTester tester) {
  final containerFinder = find.descendant(of: find.byType(QuestionButton), matching: find.byKey(const ValueKey('border-container')));

  final container = tester.widget<Container>(containerFinder);

  return container.decoration as BoxDecoration;
}

BoxDecoration _getIconContainerDecoration(WidgetTester tester) {
  final containerFinder = find.descendant(of: find.byType(QuestionButton), matching: find.byKey(const ValueKey('icon-container')));
  final container = tester.widget<Container>(containerFinder);

  return container.decoration as BoxDecoration;
}