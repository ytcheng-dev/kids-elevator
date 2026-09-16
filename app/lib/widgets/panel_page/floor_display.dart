import 'package:flutter/material.dart';

import '../../models/animate_offset.dart';
import '../../models/elevator.dart';

import '../../styles/css_manager.dart';

import 'direction_icon.dart';

class FloorDisplay extends StatelessWidget {
  const FloorDisplay(
      {super.key,
      required this.elevator,
      required this.animateOffset,
      required this.floorText});

  final Elevator elevator;
  final AnimateOffset animateOffset;

  final String floorText;

  @override
  Widget build(BuildContext context) {
    return Container(
        clipBehavior: Clip.hardEdge,
        decoration: const BoxDecoration(color: Colors.black),
        padding: const EdgeInsets.all(10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            DirectionIcon(elevator: elevator, animateOffset: animateOffset),
            Expanded(
                child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(floorText,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            color: CSSManager.screenText, fontSize: 72))))
          ],
        ));
  }
}
