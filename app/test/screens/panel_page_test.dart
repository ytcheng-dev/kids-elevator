import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elevator/constants/floor.dart';

import 'package:elevator/models/timer_manager.dart';

import 'package:elevator/interfaces/audio_player_base.dart';

import 'package:elevator/screens/panel_page.dart';

import 'package:elevator/widgets/floor_tile.dart';
import 'package:elevator/widgets/panel_page/floor_display.dart';

import 'package:elevator/styles/layout_css.dart';

import 'package:elevator/providers/volume.dart';

import '../fakes/fake_sfx_player.dart';
import '../fakes/fake_voice_player.dart';
import '../fakes/fake_volume_notifier.dart';

const Color _highlightColor = LayoutCss.secondary5,
            _shadowColor = LayoutCss.neutral2;

const _diffDuration = Duration(milliseconds: 1);

void main() {
  group('panel page', () {
    testInit();
    testFloorTileOnTap();
    testMoveSingle();
    testMoveMultiple();
    testMoveFarFloor();
  });
  
}

void testInit() {
  group('init', () {
    testWidgets('landscape screen', (WidgetTester tester) async {
      await _pumpPanelPage(tester);

      expect(find.byType(AppBar), findsNothing);
      expect(find.byType(FloorTile), findsNWidgets(7));

      final List<String> floorTitle = [for (Floor floor in Floor.values) floor.title];
      for (final title in floorTitle) {
        expect(find.byKey(ValueKey('floorTile$title')), findsOneWidget);
      }
    });

    testWidgets('portrait screen', (WidgetTester tester) async {
      _setPortraitScreen(tester);

      await _pumpPanelPage(tester);

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(FloorTile), findsNWidgets(7));

      final List<String> floorTitle = [for (Floor floor in Floor.values) floor.title];
      for (final title in floorTitle) {
        expect(find.byKey(ValueKey('floorTile$title')), findsOneWidget);
      }
    });
  });
}

void testFloorTileOnTap() {
  final floorTileB1 = ValueKey('floorTile${Floor.b1.title}');

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

    const reason = 'switch floorButton.isTarget to true';
    testWidgets(reason, (WidgetTester tester) async {
      _setPortraitScreen(tester);
      await _pumpPanelPage(tester, sfxPlayer: FakeSfxPlayer());

      final containerFider = find.descendant(of: find.byKey(floorTileB1), matching: find.byType(Container));

      // confirm init
      final initContainer = tester.widget<Container>(containerFider);
      _checkDecoration(initContainer, false, reason: '$reason: init');

      await tester.tap(find.byKey(floorTileB1));
      await tester.pump();

      final tapContainer = tester.widget<Container>(containerFider);
      _checkDecoration(tapContainer, true, reason: '$reason: tap');
    });
  });
}

void testMoveSingle() {
  group('MoveFloor(single)', () {
    const reason = 'isAllowVoice = true, move to target floor(up), open and close door';
    testWidgets(reason, (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);
      final targetFloorKey = ValueKey('floorTile${Floor.f2.title}');

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);

      // 按下目標樓層
      await tester.tap(find.byKey(targetFloorKey));
      await _checkMoveSingle(tester, voicePlayer, targetFloorKey);
    });
  
    const reason2 = 'isAllowVoice = true, move to target floor(down), open and close door';
    testWidgets(reason2, (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);
      final targetFloorKey = ValueKey('floorTile${Floor.b1.title}');

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);

      // 按下目標樓層
      await tester.tap(find.byKey(targetFloorKey));
      await _checkMoveSingle(tester, voicePlayer, targetFloorKey);
    });
  });
}

void testMoveMultiple() {
  group('MoveFloor(multiple)', () {
    const reason1 = 'isAllowVoice = true, move to up floor, open and close door';
    testWidgets(reason1, (WidgetTester tester) async {
      final floorTileStr = ['floorTile${Floor.f2.title}', 'floorTile${Floor.f3.title}', 'floorTile${Floor.f4.title}', 'floorTile${Floor.f5.title}'];
      final floorKeys = floorTileStr.map((str) => ValueKey(str)).toList();

      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);

      // 按下目標樓層
      for (ValueKey key in floorKeys) {
        await tester.tap(find.byKey(key));
      }
      
      // 逐層上樓
      for (int index = 0; index < floorTileStr.length; index++) {
        await _checkMoveSingle(tester, voicePlayer, floorKeys[index], reason: floorTileStr[index]);
      }
    });

    const reason2 = 'isAllowVoice = true, move to down floor, open and close door';
    testWidgets(reason2, (WidgetTester tester) async {
      final floorTileStr = ['floorTile${Floor.b1.title}', 'floorTile${Floor.b2.title}'];
      final floorKeys = floorTileStr.map((str) => ValueKey(str)).toList();

      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);

      // 按下目標樓層
      for (ValueKey key in floorKeys) {
        await tester.tap(find.byKey(key));
      }
      
      // 逐層下樓
      for (int index = 0; index < floorTileStr.length; index++) {
        await _checkMoveSingle(tester, voicePlayer, floorKeys[index], reason: floorTileStr[index]);
      }
    });
  });
}

void testMoveFarFloor() {
  group('MoveFloor(far away)', () {
    testWidgets('up', (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);
      final targetFloorKey = ValueKey('floorTile${Floor.f5.title}');
      final throughFloors = Floor.values.sublist(Floor.f1.index, Floor.f4.index+1);

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);
      // 點擊目標樓層
      await tester.tap(find.byKey(targetFloorKey));
      
      // 行進間
      await _checkGoThroughFloor(tester, throughFloors);

      // 檢查目標
      await _checkMoveSingle(tester, voicePlayer, targetFloorKey);
      expect(tester.hasRunningAnimations, isFalse); // 停止移動，沒有動畫
    });

    testWidgets('down', (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final voicePlayer = FakeVoicePlayer(delaySeconds: 1);
      final targetFloorKey = ValueKey('floorTile${Floor.b2.title}');
      final throughFloors = Floor.values.sublist(Floor.b1.index, Floor.f1.index+1).reversed.toList();

      await _pumpPanelPage(tester, voicePlayer: voicePlayer, isAllowVoice: true);
      // 點擊目標樓層
      await tester.tap(find.byKey(targetFloorKey));
      
      // 行進間
      await _checkGoThroughFloor(tester, throughFloors);

      // 檢查目標
      await _checkMoveSingle(tester, voicePlayer, targetFloorKey);
      expect(tester.hasRunningAnimations, isFalse); // 停止移動，沒有動畫
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

void _checkDecoration(Container container, bool isHighlight, {String? reason}) {
  final decoration = container.decoration as BoxDecoration;

  if (isHighlight) {
    expect(decoration.color, equals(LayoutCss.secondary2), reason: reason);
    expect(decoration.border, equals(Border.all(color: _highlightColor, width: 3)), reason: reason);
    expect(decoration.boxShadow!.first, equals(const BoxShadow(color: _highlightColor, offset: Offset(0, 5), blurRadius: 0)), reason: reason);
  }
  else {
    expect(decoration.color, equals(LayoutCss.secondary0), reason: reason);
    expect(decoration.border, equals(Border.all(color: _shadowColor, width: 3)), reason: reason);
    expect(decoration.boxShadow!.first, equals(const BoxShadow(color: _shadowColor, offset: Offset(0, 5), blurRadius: 0)), reason: reason);
  }
}

Future<void> _checkMoveSingle(WidgetTester tester, FakeVoicePlayer voicePlayer, ValueKey targetFloorKey, {String? reason}) async {
  await tester.pump(const Duration(seconds: TimerManager.floorTime) - _diffDuration); // 移動 1 個樓層
  // 樓層還沒移動完 -> 還不能播語音
  expect(voicePlayer.isPlaying, isFalse, reason: reason);
  expect(tester.hasRunningAnimations, isTrue, reason: reason); 
  // ding 開始播 -> 上樓動畫還在跑 -> 驗證動畫
  await tester.pump(_diffDuration); 
  expect(voicePlayer.isPlaying, isTrue, reason: reason);        // 播放 ding
  expect(voicePlayer.waitForPlay, equals(1), reason: reason);   // 樓層語音等待播放
  expect(tester.hasRunningAnimations, isTrue, reason: reason);  // 驗證動畫

  // ding 播完前
  await tester.pump(Duration(seconds: voicePlayer.delaySeconds) - _diffDuration);  
  expect(voicePlayer.isPlaying, isTrue, reason: reason);        // 播放 ding
  expect(voicePlayer.waitForPlay, equals(1), reason: reason);   // 樓層語音等待播放
  expect(tester.hasRunningAnimations, isTrue, reason: reason);  // 驗證動畫
  // 推進時間 -> ding 播完 -> 上樓動畫結束
  await tester.pump(_diffDuration);
  expect(tester.hasRunningAnimations, isFalse, reason: reason);
  expect(voicePlayer.waitForPlay, equals(0), reason: reason);   // 樓層語音開始播放

  // 樓層語音結束前
  await tester.pump(Duration(seconds: voicePlayer.delaySeconds) - _diffDuration);
  expect(tester.hasRunningAnimations, isFalse, reason: reason);
  expect(voicePlayer.isPlaying, isTrue, reason: reason);
  // 推進時間 -> 樓層語音結束 -> 開門動畫開始, isTarget = false(畫面重繪)
  await tester.pump(_diffDuration);
  expect(tester.hasRunningAnimations, isTrue, reason: reason);

  final containerFider = find.descendant(of: find.byKey(targetFloorKey), matching: find.byType(Container));
  final container = tester.widget<Container>(containerFider);

  _checkDecoration(container, false, reason: '${reason == null ? '' : '$reason: '}isTarget = false');

  // 開門動畫結束前
  await tester.pump(const Duration(seconds: TimerManager.doorProcTime) - _diffDuration);
  expect(tester.hasRunningAnimations, isTrue, reason: reason);
  // 推進時間 -> 開門動畫結束
  await tester.pump(_diffDuration);
  expect(voicePlayer.isPlaying, isFalse, reason: reason);   // 開門語音播完
  expect(tester.hasRunningAnimations, isFalse, reason: reason);

  // 關門動畫開始前
  await tester.pump(const Duration(seconds: TimerManager.openWaitingTime) - _diffDuration);
  expect(voicePlayer.isPlaying, isFalse, reason: reason);
  expect(tester.hasRunningAnimations, isFalse, reason: reason);
  // 推進時間 -> 關門動畫開始
  await tester.pump(_diffDuration);
  expect(voicePlayer.isPlaying, isTrue, reason: reason);   // 關門語音
  expect(tester.hasRunningAnimations, isTrue, reason: reason);

  // 關門動畫結束前
  await tester.pump(const Duration(seconds: TimerManager.doorProcTime) - _diffDuration);
  expect(tester.hasRunningAnimations, isTrue, reason: reason);
  // 推進時間 -> 關門動畫結束
  await tester.pump(_diffDuration);
  expect(voicePlayer.isPlaying, isFalse, reason: reason);  // 關門語音結束
  expect(tester.hasRunningAnimations, isFalse, reason: reason);
  // 推進時間: doSwitch
  await tester.pump(const Duration(milliseconds: TimerManager.switchTime));
}

Future<void> _checkGoThroughFloor(WidgetTester tester, List<Floor> throughFloors) async {
  for (int i = 1; i < throughFloors.length; i++ ) {
    // 到達前
    await tester.pump(const Duration(seconds: TimerManager.floorTime) - _diffDuration);
    // 樓層不變
    final textFinder = find.descendant(of: find.byType(FloorDisplay), matching: find.text(throughFloors[i-1].title));
    expect(textFinder, findsOneWidget);

    // 到達
    await tester.pump(_diffDuration);
    // 樓層改變
    final arrTextFinder = find.descendant(of: find.byType(FloorDisplay), matching: find.text(throughFloors[i].title));
    expect(arrTextFinder, findsOneWidget);
  }
}