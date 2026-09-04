import 'package:flutter/material.dart';

class AnimateOffset {
  AnimateOffset({required AnimationController animateController})
      : leftOpenOffset = Tween<Offset>(
                begin: const Offset(horizontalOffset, 0),
                end: const Offset(-horizontalOffset, 0))
            .animate(animateController),
        rightOpenOffset = Tween<Offset>(
                begin: const Offset(-horizontalOffset, 0),
                end: const Offset(horizontalOffset, 0))
            .animate(animateController),
        leftCloseOffset = Tween<Offset>(
                begin: const Offset(-horizontalOffset, 0),
                end: const Offset(horizontalOffset, 0))
            .animate(animateController),
        rightCloseOffset = Tween<Offset>(
                begin: const Offset(horizontalOffset, 0),
                end: const Offset(-horizontalOffset, 0))
            .animate(animateController),
        upFloorOffset = Tween<Offset>(
                begin: const Offset(0, verticalOffset),
                end: const Offset(0, -verticalOffset))
            .animate(animateController),
        downFloorOffset = Tween<Offset>(
                begin: const Offset(0, -verticalOffset),
                end: const Offset(0, verticalOffset))
            .animate(animateController);

  static const double horizontalOffset = 0.3, verticalOffset = 1;

  final Animation<Offset> leftOpenOffset,
      rightOpenOffset,
      leftCloseOffset,
      rightCloseOffset,
      upFloorOffset,
      downFloorOffset;
}
