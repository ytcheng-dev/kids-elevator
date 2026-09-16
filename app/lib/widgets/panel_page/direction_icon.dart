import 'package:flutter/material.dart';

import '../../models/animate_offset.dart';
import '../../models/elevator.dart';
import '../../models/enums.dart';

import '../arrow_icon.dart';

class DirectionIcon extends StatelessWidget {
  const DirectionIcon(
      {super.key, required this.elevator, required this.animateOffset});

  final Elevator elevator;
  final AnimateOffset animateOffset;

  @override
  Widget build(BuildContext context) {
    if (elevator.direction == Direction.idle) {
      if (elevator.doorStatus == DoorStatus.opening) {
        return Expanded(
            child: Row(children: <Widget>[
          Expanded(
              child: SlideTransition(
                  position: animateOffset.leftOpenOffset,
                  child: const ArrowIcon(directionIcon: ScreenIcon.left))),
          Expanded(
              child: SlideTransition(
                  position: animateOffset.rightOpenOffset,
                  child: const ArrowIcon(directionIcon: ScreenIcon.right)))
        ]));
      } else if (elevator.doorStatus == DoorStatus.closing) {
        return Expanded(
            child: Row(children: <Widget>[
          Expanded(
              child: SlideTransition(
                  position: animateOffset.leftCloseOffset,
                  child: const ArrowIcon(directionIcon: ScreenIcon.right))),
          Expanded(
              child: SlideTransition(
                  position: animateOffset.rightCloseOffset,
                  child: const ArrowIcon(directionIcon: ScreenIcon.left)))
        ]));
      } else {
        return const Spacer();
      }
    } else if (elevator.direction == Direction.up) {
      return Expanded(
          child: SlideTransition(
              position: animateOffset.upFloorOffset,
              child: const ArrowIcon(directionIcon: ScreenIcon.up)));
    } else {
      return Expanded(
          child: SlideTransition(
              position: animateOffset.downFloorOffset,
              child: const ArrowIcon(directionIcon: ScreenIcon.down)));
    }
  }
}
