import 'package:flutter/material.dart';

import '../models/enums.dart';

import '../styles/css_manager.dart';

class ArrowIcon extends StatelessWidget {
  const ArrowIcon({super.key, required this.directionIcon});
  
  final ScreenIcon directionIcon;

  @override
  Widget build(BuildContext context) {
    Icon rtnIcon;

    switch (directionIcon) {
      case ScreenIcon.up:
        rtnIcon = const Icon(
            Icons.arrow_upward,
            color: Colors.green,
            size: 96
          );
      break;
      case ScreenIcon.down:
        rtnIcon = const Icon(
            Icons.arrow_downward,
            color: Colors.green,
            size: 96
          );
      break;
      case ScreenIcon.left:
        rtnIcon = const Icon(
            Icons.chevron_left,
            color: CSSManager.screenText,
            size: 96
          );
      break;
      case ScreenIcon.right:
        rtnIcon = const Icon(
            Icons.chevron_right,
            color: CSSManager.screenText,
            size: 96
          );
      break;
    }

    return FittedBox(
          fit: BoxFit.contain,
          child: rtnIcon
    );
  }
  
}