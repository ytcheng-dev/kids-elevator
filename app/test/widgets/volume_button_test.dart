import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';

import 'package:elevator/models/enums.dart';

import 'package:elevator/widgets/volume_button.dart';

void main() {
  group('widgets/volume_button', () {
    testInit();
    testOnPressed();
  });
}

void testInit() {
  testWidgets('init sfx, isAllow = true', (WidgetTester tester) async {
    await _pumpVolumeButton(tester, VolumeType.sfx, true);

    IconData? icon = _getIcon(tester);

    expect(icon, equals(Icons.volume_up));
  });

  testWidgets('init sfx, isAllow = false', (WidgetTester tester) async {
    await _pumpVolumeButton(tester, VolumeType.sfx, false);

    IconData? icon = _getIcon(tester);

    expect(icon, equals(Icons.volume_off));
  });

  testWidgets('init voice, isAllow = true', (WidgetTester tester) async {
    await _pumpVolumeButton(tester, VolumeType.voice, true);

    IconData? icon = _getIcon(tester);

    expect(icon, equals(Icons.music_note));
  });

  testWidgets('init voice, isAllow = false', (WidgetTester tester) async {
    await _pumpVolumeButton(tester, VolumeType.voice, false);

    IconData? icon = _getIcon(tester);

    expect(icon, equals(Icons.music_off));
  });
}

void testOnPressed() {
  testWidgets('onPressed', (WidgetTester tester) async {
    int counter = 0;
    await _pumpVolumeButton(tester, VolumeType.sfx, true, onPressed: () {
      counter++;
    });

    expect(counter, equals(0));

    await tester.tap(find.byType(VolumeButton));
    expect(counter, equals(1));

    await tester.tap(find.byType(VolumeButton));
    await tester.tap(find.byType(VolumeButton));
    
    expect(counter, equals(3));
  });

  testWidgets('onPressed-no function set in', (WidgetTester tester) async {
      await _pumpVolumeButton(tester, VolumeType.sfx, true);

      // 點擊
      await tester.tap(find.byType(VolumeButton));
      await tester.pump();

      expect(tester.takeException(), isNull);

    });
}

Future<void> _pumpVolumeButton(WidgetTester tester, VolumeType volumeType, bool isAllow, {VoidCallback? onPressed}) {
  return tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: VolumeButton(isAllow: isAllow, volumeType: volumeType, onPressed: onPressed)
      )
    )
  );
}

IconData? _getIcon(WidgetTester tester) {
  final iconBtnFinder = find.descendant(
    of: find.byType(VolumeButton), 
    matching: find.byType(IconButton));

  final iconButton = tester.widget<IconButton>(iconBtnFinder);
  final icon = iconButton.icon as Icon;

  return icon.icon;
}