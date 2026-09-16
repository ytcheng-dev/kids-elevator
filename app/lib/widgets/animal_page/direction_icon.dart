import 'package:flutter/material.dart';

import '../../models/animate_offset.dart';
import '../../models/enums.dart';

import '../arrow_icon.dart';

class DirectionIcon extends StatelessWidget {
  const DirectionIcon({
    super.key,
    required this.direction,
    required this.animateOffset
  });

  final Direction direction;
  final AnimateOffset animateOffset;

  @override
  Widget build(BuildContext context) {
    if (direction == Direction.up) {
      return Expanded(
        child: SlideTransition(
          position: animateOffset.upFloorOffset,
          child: const ArrowIcon(directionIcon: ScreenIcon.up)
        )
      );
    }
    else if (direction == Direction.down) {
      return Expanded(
        child: SlideTransition(
          position: animateOffset.downFloorOffset,
          child: const ArrowIcon(directionIcon: ScreenIcon.down)
        )
      );
    }
    else {
      return const Spacer();
    }
  }
}