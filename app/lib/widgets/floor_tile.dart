import 'package:flutter/material.dart';

import '../models/panel_buttons.dart';

import '../styles/layout_css.dart';

class FloorTile extends StatefulWidget {
  const FloorTile ({
    super.key,
    required this.floorButton,
    this.onTap
  });

  final FloorButton floorButton;

  final VoidCallback? onTap;

  @override
  State<FloorTile> createState() => _FloorTileState();
}

class _FloorTileState extends State<FloorTile> {
  _FloorTileState();

  bool _isPressed = false;

  final Color highlightColor = LayoutCss.secondary5,
              shadowColor = LayoutCss.neutral2;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (tapDownDetails) {
        setState(() {
          _isPressed = true;
        });
      },
      onTapUp: (tapUpDetails) {
        setState(() {
          _isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          _isPressed = false;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: LayoutCss.p2,
        decoration: BoxDecoration(
          color: widget.floorButton.isTarget ? LayoutCss.secondary2 : LayoutCss.secondary0,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: widget.floorButton.isTarget ? highlightColor : shadowColor,
            width: 3
          ),
          boxShadow: [_getShadow()]
        ),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            widget.floorButton.title,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 48,
              fontWeight: FontWeight.bold,
              color: widget.floorButton.isTarget ? highlightColor : LayoutCss.text1
            )
          )
        )
      )
    );
  }

  BoxShadow _getShadow() {
    if (widget.floorButton.isTarget) {
      return BoxShadow(
        color: highlightColor,
        offset: const Offset(0, 5),
        blurRadius: 0
      );
    }
    else {
      return _isPressed ? 
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0,1),
              blurRadius: 0
            )
           : 
            BoxShadow(
              color: shadowColor,
              offset: const Offset(0,5),
              blurRadius: 0
            );
          
    }
  }
}