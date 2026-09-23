import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elevator/screens/home_page.dart';

import 'package:elevator/widgets/volume_button.dart';

import 'package:elevator/providers/volume.dart';

import '../fakes/fake_volume_notifier.dart';

void main() {
  group('home page', () {
    testInit();
    testProvider();
  });
}

void testInit() {
  testWidgets('init', (WidgetTester tester) async {
    _setPortraitScreen(tester);

    await tester.pumpWidget(
        const ProviderScope(child: MaterialApp(home: HomePage())
      ));

    expect(find.byType(ElevatedButton), findsNWidgets(2));
    expect(find.byType(VolumeButton), findsNWidgets(2));

    final sfxButton = tester.widget<VolumeButton>(
      find.descendant(
        of: find.byKey(const ValueKey('volumeRow')),
        matching: find.byKey(const ValueKey('volumeSFX'))
      )
    );
    final voiceButton = tester.widget<VolumeButton>(
      find.descendant(
        of: find.byKey(const ValueKey('volumeRow')),
        matching: find.byKey(const ValueKey('volumeVoice'))
      )
    );

    expect(sfxButton.isAllow, isTrue);
    expect(voiceButton.isAllow, isTrue);
  });
}

void testProvider() {
  testWidgets('volume provider isAllowSfx = false, isAllowVoice = false', (WidgetTester tester) async {
    _setPortraitScreen(tester);

    await tester.pumpWidget(
        ProviderScope(
          overrides: [
            volumeProvider.overrideWith(() => FakeVolumeNotifier())
          ],
          child: const MaterialApp(home: HomePage()
        )
      ));

    final sfxButton = tester.widget<VolumeButton>(
      find.descendant(
        of: find.byKey(const ValueKey('volumeRow')),
        matching: find.byKey(const ValueKey('volumeSFX'))
      )
    );
    final voiceButton = tester.widget<VolumeButton>(
      find.descendant(
        of: find.byKey(const ValueKey('volumeRow')),
        matching: find.byKey(const ValueKey('volumeVoice'))
      )
    );

    expect(sfxButton.isAllow, isFalse);
    expect(voiceButton.isAllow, isFalse);
  });
}

void _setPortraitScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
    tester.view.physicalSize = const Size(400, 800);
    addTearDown(tester.view.reset);   // 註冊結束測試後還原
}