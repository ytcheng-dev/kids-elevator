import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:audioplayers/audioplayers.dart';

import 'package:elevator/models/sfx_player.dart';

import '../mocks/mock_audioplayers_platform.dart';

void main() {
  group('models/sfx_player', () {
    late MockAudioPlayersPlatform mockPlatform;

    setUp(() async {
      mockPlatform = MockAudioPlayersPlatform();

      await mockPlatform.init();
    });

    tearDown(() async {
      await mockPlatform.dispose();
    });

    MockAudioPlayersPlatform getPlatform() {
      return mockPlatform;
    }

    testInit(getPlatform);
    testRequest(getPlatform);
    
  });
}

void testInit(MockAudioPlayersPlatform Function() getPlatform) {
  test('init, default none audio Focus', () async {
    final mockPlatform = getPlatform();

    SfxPlayer();
    await mockPlatform.waitForSetAudioContext();

    expect(mockPlatform.getMethodStrings(), contains('setAudioContext'));
    final setAudioContext = mockPlatform.findTargetMethod('setAudioContext');

    expect(setAudioContext.arguments['audioFocus'], equals(AndroidAudioFocus.none.value));
  });
}

void testRequest(MockAudioPlayersPlatform Function() getPlatform) {
  test('request, isAllow = true', () async {
    final mockPlatform = getPlatform();

    final sfxPlayer = SfxPlayer();
    sfxPlayer.request(isAllow: true);
    
    await mockPlatform.waitForResume();

    expect(mockPlatform.getMethodStrings(), contains('setSourceUrl'));
    final MethodCall setSourceUrlCall = mockPlatform.findTargetMethod('setSourceUrl');
    final String fileUrl = setSourceUrlCall.arguments['url'];

    expect(fileUrl, endsWith('sounds/panel/button.mp3'));
    expect(mockPlatform.getMethodStrings(), contains('resume'));
  });

  test('request, isAllow = false', () async {
    final mockPlatform = getPlatform();

    final sfxPlayer = SfxPlayer();
    sfxPlayer.request(isAllow: false);
    await mockPlatform.waitForSetAudioContext();
    // 因為 resume 不會發生，沒有辦法透過等 resume 確認要等多久，暫時先用固定等待時間做驗證
    await Future.delayed(const Duration(seconds: 1));

    expect(mockPlatform.getMethodStrings(), isNot(contains('setSourceUrl')));
  });

  test('request, quick double click', () async {
    final mockPlatform = getPlatform();

    final sfxPlayer = SfxPlayer();
    sfxPlayer.request(isAllow: true);
    sfxPlayer.request(isAllow: true);
    await mockPlatform.waitForResume();
    await Future.delayed(const Duration(seconds: 1)); // TODO: 怎麼確定第二次沒有執行要等多久

    final perMethodList = mockPlatform.perMethodList;

    expect(mockPlatform.getMethodStrings(), contains('resume'));
    expect(perMethodList.where((c) => c.method == 'resume').length, equals(1));
  });

  test('request, play finish then click', () async {
    final mockPlatform = getPlatform();

    final sfxPlayer = SfxPlayer();
    sfxPlayer.request(isAllow: true);
    await mockPlatform.waitForResume();
    // finish
    mockPlatform.pushComplete();
    await Future.delayed(const Duration(seconds: 1));    // TODO: 等什麼事件?

    sfxPlayer.request(isAllow: true);
    await Future.delayed(const Duration(seconds: 1));     // TODO: 要等第二次 resume

    final perMethodList = mockPlatform.perMethodList;

    expect(perMethodList.where((c) => c.method == 'resume').length, equals(2));
  });
}