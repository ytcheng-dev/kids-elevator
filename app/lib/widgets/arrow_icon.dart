import 'package:flutter/material.dart';

import '../models/enums.dart';

import '../styles/layout_css.dart';

class ArrowIcon extends StatelessWidget {
  const ArrowIcon({super.key, required this.directionIcon});

  final ScreenIcon directionIcon;

  @override
  Widget build(BuildContext context) {
    Icon rtnIcon;

    switch (directionIcon) {
      case ScreenIcon.up:
        rtnIcon = const Icon(Icons.arrow_upward, color: LayoutCss.primary, size: 96);
        break;
      case ScreenIcon.down:
        rtnIcon =
            const Icon(Icons.arrow_downward, color: LayoutCss.primary, size: 96);
        break;
      case ScreenIcon.left:
        rtnIcon = const Icon(Icons.chevron_left,
            color: LayoutCss.secondary, size: 96);
        break;
      case ScreenIcon.right:
        rtnIcon = const Icon(Icons.chevron_right,
            color: LayoutCss.secondary, size: 96);
        break;
    }

    return FittedBox(fit: BoxFit.contain, child: rtnIcon);
  }
}
