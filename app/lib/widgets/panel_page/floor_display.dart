import 'package:flutter/material.dart';

import '../../models/animate_offset.dart';
import '../../models/elevator.dart';

import '../../styles/layout_css.dart';

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
        margin: LayoutCss.mb1,
        decoration: BoxDecoration(
          color: LayoutCss.neutral9,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: LayoutCss.neutral8,
            width: 10
          )
        ),
        clipBehavior: Clip.hardEdge,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: <Widget>[
            DirectionIcon(elevator: elevator, animateOffset: animateOffset),
            Expanded(
                child: FittedBox(
                    fit: BoxFit.contain,
                    child: Text(floorText,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: LayoutCss.secondary, 
                            fontSize: LayoutCss.h1
                          ))))
          ],
        ));
  }
}
