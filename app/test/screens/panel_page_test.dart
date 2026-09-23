import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:elevator/interfaces/audio_player_base.dart';

import 'package:elevator/screens/panel_page.dart';

import 'package:elevator/widgets/floor_tile.dart';

import 'package:elevator/styles/layout_css.dart';

import '../fakes/fake_sfx_player.dart';

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
  group('floorTile onTap: ', () {
    testWidgets('SfxPlayer request', (WidgetTester tester) async {
      _setPortraitScreen(tester);
      final FakeSfxPlayer sfxPlayer = FakeSfxPlayer();

      await _pumpPanelPage(tester, sfxPlayer: sfxPlayer);

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
  });
}

void _setPortraitScreen(WidgetTester tester) {
  tester.view.devicePixelRatio = 1.0;
  tester.view.physicalSize = const Size(400, 800);
  addTearDown(tester.view.reset);   // 註冊結束測試後還原
}

Future<void> _pumpPanelPage(WidgetTester tester, {SfxPlayerBase? sfxPlayer}) {
  return tester.pumpWidget(
    ProviderScope(
      child: MaterialApp(
        home: PanelPage(
          sfxPlayer: sfxPlayer
        ))
  ));
}