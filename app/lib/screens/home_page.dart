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
    return Scaffold(
      backgroundColor: LayoutCss.defaultBG,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: <Widget>[
            _getMenuButton(
              '面板模式', 'assets/images/home_page/normal.png', 
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const PanelPage())
                );
              }  
            ),
            const SizedBox(height: 10),
            _getMenuButton(
              '動物模式', 'assets/images/home_page/animal.png',
              () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AnimalPage())
                );
              }
            ),
            const SizedBox(height: 10),
            Row(
              children: <Widget>[
                _getVolumeButton(ref, VolumeType.sfx),
                _getVolumeButton(ref, VolumeType.voice)
              ]
            )
          ]
        )
        )
      )
    );
  }
}

ElevatedButton _getMenuButton(String title, String imgFile, VoidCallback onPressed) {
  return ElevatedButton(
    onPressed: onPressed,
    style: ElevatedButton.styleFrom(
      padding: EdgeInsets.zero,
    ),
    child: Ink.image(
      image: AssetImage(imgFile),
      fit: BoxFit.cover,
      child: AspectRatio(
            aspectRatio: 2.4,
            child: Center(
              child: Text(
              title,
              style: const TextStyle(
                color: LayoutCss.text1,
                fontSize: 30
              )
              )
            )
          )
    )
  );
}

Widget _getVolumeButton(WidgetRef ref, VolumeType vType) {
  return VolumeButton(
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