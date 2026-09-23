import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elevator/models/timer_manager.dart';

import 'package:elevator/interfaces/audio_player_base.dart';

import 'package:elevator/screens/panel_page.dart';

import 'package:elevator/widgets/floor_tile.dart';

import 'package:elevator/styles/layout_css.dart';

import 'package:elevator/providers/volume.dart';

import '../fakes/fake_sfx_player.dart';
import '../fakes/fake_voice_player.dart';
import '../fakes/fake_volume_notifier.dart';

void main() {
  group('panel page', () {
    testInit();
    testFloorTileOnTap();
  });
  
}

void testInit() {
  group('init', () {
    testWidgets('landscape screen', (WidgetTester tester) async {
      await _pumpPanelPage(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FloorTile), findsNWidgets(7));

      const List<String> floorTitle = ['B2', 'B1', '1', '2', '3', '4', '5'];
      for (final title in floorTitle) {
        expect(find.byKey(ValueKey('floorTile$title')), findsOneWidget);
      }
    });

    testWidgets('portrait screen', (WidgetTester tester) async {
      _setPortraitScreen(tester);

      await _pumpPanelPage(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloorTile), findsNWidgets(7));

      const List<String> floorTitle = ['B2', 'B1', '1', '2', '3', '4', '5'];
      for (final title in floorTitle) {
        expect(find.byKey(ValueKey('floorTile$title')), findsOneWidget);
      }
    });
  });
}

void testFloorTileOnTap() {
  const floorTileB1 = ValueKey('floorTileB1');

  const Color highlightColor = LayoutCss.secondary5,
              shadowColor = LayoutCss.neutral2;

  const diffDuration = Duration(milliseconds: 1);

  group('floorTile onTap: ', () {
    testWidgets('SfxPlayer request', (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final FakeSfxPlayer sfxPlayer = FakeSfxPlayer();

      await _pumpPanelPage(tester, sfxPlayer: sfxPlayer, isAllowSfx: true);

      expect(find.byType(FloorTile), findsNWidgets(7));

      await tester.tap(find.byKey(floorTileB1));
      await tester.pump();

      expect(sfxPlayer.isPlaying, isTrue);
    });

    testWidgets('switch floorButton.isTarget to true', (WidgetTester tester) async {
      _setPortraitScreen(tester);
      await _pumpPanelPage(tester, sfxPlayer: FakeSfxPlayer());

      final containerFider = find.descendant(of: find.byKey(floorTileB1), matching: find.byType(Container));

      // confirm init
      final initContainer = tester.widget<Container>(containerFider),
            initDecoration = initContainer.decoration as BoxDecoration;

      expect(initDecoration.color, equals(LayoutCss.secondary0));
      expect(initDecoration.border, equals(Border.all(color: shadowColor, width: 3)));
      expect(initDecoration.boxShadow!.first, equals(const BoxShadow(color: shadowColor, offset: Offset(0, 5), blurRadius: 0)));

      await tester.tap(find.byKey(floorTileB1));
      await tester.pump();

      final tapContainer = tester.widget<Container>(containerFider),
            tapDecoration = tapContainer.decoration as BoxDecoration;

      expect(tapDecoration.color, equals(LayoutCss.secondary2));
      expect(tapDecoration.border, equals(Border.all(color: highlightColor, width: 3)));
      expect(tapDecoration.boxShadow!.first, equals(const BoxShadow(color: highlightColor, offset: Offset(0, 5), blurRadius: 0)));
    });

    testWidgets('isAllowVoice = true, move to target floor(up), open and close door', (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);
      const targetFloorKey = ValueKey('floorTile2');

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);

      // 按下目標樓層
      await tester.tap(find.byKey(targetFloorKey));
      await tester.pump(const Duration(seconds: TimerManager.floorTime) - diffDuration); // 移動 1 個樓層
      // 樓層還沒移動完 -> 還不能播語音
      expect(voicePlayer.isPlaying, isFalse);
      expect(tester.hasRunningAnimations, isTrue); 
      // ding 開始播 -> 上樓動畫還在跑 -> 驗證動畫
      await tester.pump(diffDuration); 
      expect(voicePlayer.isPlaying, isTrue);        // 播放 ding
      expect(voicePlayer.waitForPlay, equals(1));   // 樓層語音等待播放
      expect(tester.hasRunningAnimations, isTrue);  // 驗證動畫

      // ding 播完前
      await tester.pump(Duration(seconds: voicePlayer.delaySeconds) - diffDuration);  
      expect(voicePlayer.isPlaying, isTrue);        // 播放 ding
      expect(voicePlayer.waitForPlay, equals(1));   // 樓層語音等待播放
      expect(tester.hasRunningAnimations, isTrue);  // 驗證動畫
      // 推進時間 -> ding 播完 -> 上樓動畫結束
      await tester.pump(diffDuration);
      expect(tester.hasRunningAnimations, isFalse);
      expect(voicePlayer.waitForPlay, equals(0));   // 樓層語音開始播放

      // 樓層語音結束前
      await tester.pump(Duration(seconds: voicePlayer.delaySeconds) - diffDuration);
      expect(tester.hasRunningAnimations, isFalse);
      expect(voicePlayer.isPlaying, isTrue);
      // 推進時間 -> 樓層語音結束 -> 開門動畫開始, isTarget = false(畫面重繪)
      await tester.pump(diffDuration);
      expect(tester.hasRunningAnimations, isTrue);

      final containerFider = find.descendant(of: find.byKey(targetFloorKey), matching: find.byType(Container));
      final container = tester.widget<Container>(containerFider),
            decoration = container.decoration as BoxDecoration;

      expect(decoration.color, equals(LayoutCss.secondary0));
      expect(decoration.border, equals(Border.all(color: shadowColor, width: 3)));
      expect(decoration.boxShadow!.first, equals(const BoxShadow(color: shadowColor, offset: Offset(0, 5), blurRadius: 0)));

      // 開門動畫結束前
      await tester.pump(const Duration(seconds: TimerManager.doorProcTime) - diffDuration);
      expect(tester.hasRunningAnimations, isTrue);
      // 推進時間 -> 開門動畫結束
      await tester.pump(diffDuration);
      expect(voicePlayer.isPlaying, isFalse);   // 開門語音播完
      expect(tester.hasRunningAnimations, isFalse);

      // 關門動畫開始前
      await tester.pump(const Duration(seconds: TimerManager.openWaitingTime) - diffDuration);
      expect(voicePlayer.isPlaying, isFalse);
      expect(tester.hasRunningAnimations, isFalse);
      // 推進時間 -> 關門動畫開始
      await tester.pump(diffDuration);
      expect(voicePlayer.isPlaying, isTrue);   // 關門語音
      expect(tester.hasRunningAnimations, isTrue);

      // 關門動畫結束前
      await tester.pump(const Duration(seconds: TimerManager.doorProcTime) - diffDuration);
      expect(tester.hasRunningAnimations, isTrue);
      // 推進時間 -> 關門動畫結束
      await tester.pump(diffDuration);
      expect(voicePlayer.isPlaying, isFalse);  // 關門語音結束
      expect(tester.hasRunningAnimations, isFalse);
    });
  });
}

void _setPortraitScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);   // 註冊結束測試後還原
}

Future<void> _pumpPanelPage(WidgetTester tester, {bool isAllowSfx = false, bool isAllowVoice = false, SfxPlayerBase? sfxPlayer, VoicePlayerBase? voicePlayer}) {
  return tester.pumpWidget(
    ProviderScope(
      overrides: [
        volumeProvider.overrideWith(() => FakeVolumeNotifier(isAllowSfx: isAllowSfx, isAllowVoice: isAllowVoice))
      ],
      child: MaterialApp(
        home: PanelPage(
          sfxPlayer: sfxPlayer ?? FakeSfxPlayer(),
          voicePlayer: voicePlayer ?? FakeVoicePlayer(delaySeconds: 1)
        ))
  ));
}