import 'package:flutter/material.dart';

import '../models/enums.dart';

import '../styles/layout_css.dart';

class VolumeButton extends StatelessWidget {
  const VolumeButton(
      {super.key,
      required this.volumeType,
      required this.isAllow,
      this.onPressed});

  final VolumeType volumeType;
  final bool isAllow;

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    IconData icon;

    if (volumeType == VolumeType.sfx) {
      icon = isAllow ? Icons.volume_up : Icons.volume_off;
    } else {
      icon = isAllow ? Icons.music_note : Icons.music_off;
    }

    return IconButton(
      icon: Icon(icon), 
      style: IconButton.styleFrom(
        foregroundColor: LayoutCss.primary7,
        backgroundColor: LayoutCss.surface,
        shape: const CircleBorder(),
        elevation: 6,
        // side: const BorderSide(color: LayoutCss.neutral2)
      ),
      onPressed: onPressed);
  }
}
