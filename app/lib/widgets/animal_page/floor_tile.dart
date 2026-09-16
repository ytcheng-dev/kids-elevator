import 'package:flutter/material.dart';

import '../../models/panel_buttons.dart';

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

  bool isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      onTapDown: (tapDownDetails) {
        setState(() {
          isPressed = true;
        });
      },
      onTapUp: (tapUpDetails) {
        setState(() {
          isPressed = false;
        });
      },
      onTapCancel: () {
        setState(() {
          isPressed = false;
        });
      },
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: widget.floorButton.isTarget ? const Color(0xFFFFEDE2) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: const Color(0xFFDDD6CC),
            width: 1
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
              color: widget.floorButton.isTarget ? const Color(0xFF6D3A00) : Colors.black
            )
          )
        )
      )
    );
  }

  BoxShadow _getShadow() {
    if (widget.floorButton.isTarget) {
      return const BoxShadow(
        color: Color(0xFF6D3A00),
        offset: Offset(0, 5),
        blurRadius: 3
      );
    }
    else {
      return isPressed ? 
            const BoxShadow(
              color: Color(0xFF665D52),
              offset: Offset(0,1),
              blurRadius: 1
            )
           : 
            const BoxShadow(
              color: Color(0xFF665D52),
              offset: Offset(0,5),
              blurRadius: 3
            );
          
    }
  }
}