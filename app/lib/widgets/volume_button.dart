import 'package:flutter/material.dart';

import '../models/enums.dart';

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

    return IconButton(icon: Icon(icon), onPressed: onPressed);
  }
}
