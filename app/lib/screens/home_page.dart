import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'panel_page.dart';
import 'animal_page.dart';

import '../models/enums.dart';

import '../widgets/volume_button.dart';

import '../providers/volume.dart';

import '../styles/layout_css.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;

    // LayoutCss setting
    LayoutCss.textSizeBase = screenWidth * 0.04;
    LayoutCss.marginBase = screenWidth * 0.01;

    return Scaffold(
      backgroundColor: LayoutCss.defaultBG,
      body: SafeArea(
        child: Padding(
          padding: LayoutCss.m2,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Expanded(
                flex: 2,
                child: Container(
                  padding: LayoutCss.p3,
                  child: const FittedBox(
                    fit: BoxFit.contain,
                    child: Image(image: AssetImage('assets/images/home_page/icon.png'))
                  ))
              ),
              Expanded(
                flex: 1,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Text(
                      '小小電梯大冒險',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LayoutCss.text1,
                        fontSize: LayoutCss.h1,
                        fontWeight: FontWeight.bold
                      )
                    ),
                    Text(
                      '快樂探索 ‧ 動動小手指',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: LayoutCss.text2,
                        fontSize: LayoutCss.h5
                      )
                    )
                  ]
                )
              ),
              Expanded(
                flex: 5,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    Expanded(
                      child: _getMenuButton(MenuButtonTarget.panel, context)
                    ),
                    Expanded(
                      child: _getMenuButton(MenuButtonTarget.animal, context)
                    )
                  ]
                )
              ),
              Expanded(
                flex: 2,
                child: Row(
                  key: const ValueKey('volumeRow'),
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    _getVolumeButton(ref, VolumeType.sfx),
                    _getVolumeButton(ref, VolumeType.voice)
                  ]
                )
              )
            ]
          )
        )
      )
    );
  }
}

Widget _getMenuButton(MenuButtonTarget menuBtnTarget, BuildContext context) {
  String title;
  String imgFile;
  WidgetBuilder targetPageBuilder;
  Color textColor;
  Color borderColor;

  switch(menuBtnTarget) {
    case MenuButtonTarget.panel:
      title = '面板模式';
      imgFile = 'assets/images/home_page/panel.png';
      targetPageBuilder = (context) => const PanelPage();
      textColor = LayoutCss.secondary6;
      borderColor = LayoutCss.secondary2;
      break;
    case MenuButtonTarget.animal:
      title = '動物模式';
      imgFile = 'assets/images/home_page/animal.png';
      targetPageBuilder = (context) => const AnimalPage();
      textColor = LayoutCss.primary7;
      borderColor = LayoutCss.primary2;
      break;
  }


  return Container(
      margin: LayoutCss.m2,
      decoration: BoxDecoration(
        color: LayoutCss.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: borderColor,
            offset: const Offset(0, 4),
            blurRadius: 0
          )
        ]
      ),
      child: ElevatedButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: targetPageBuilder)
          );
        },
        style: ElevatedButton.styleFrom(
          padding: LayoutCss.p3,
          elevation: 0,
          backgroundColor: Colors.transparent,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20)
          )
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: LayoutCss.h1
              )
            ),
            Container(
              padding: LayoutCss.p2,
              child: Ink.image(
                image: AssetImage(imgFile),
                fit: BoxFit.cover,
                child: const AspectRatio(
                  aspectRatio: 1
                )
              )
              // child: FittedBox(
              //   fit: BoxFit.contain,
              //   child: Image(image: AssetImage(imgFile))
              // )
            )
          ]
        )
      )
    );
}

Widget _getVolumeButton(WidgetRef ref, VolumeType vType) {
  return VolumeButton(
      key: vType == VolumeType.sfx ? const ValueKey('volumeSFX') : const ValueKey('volumeVoice'),
      isAllow: vType == VolumeType.sfx
          ? ref.watch(volumeProvider).isAllowSfx
          : ref.watch(volumeProvider).isAllowVoice,
      volumeType: vType,
      onPressed: () {
        if (vType == VolumeType.sfx) {
          ref.read(volumeProvider.notifier).toggleSfx();
        }
        else {
          ref.read(volumeProvider.notifier).toggleVoice();
        }
      });
}