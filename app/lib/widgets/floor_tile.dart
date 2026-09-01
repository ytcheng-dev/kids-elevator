import 'package:flutter/material.dart';

import '../models/board_button.dart';
import '../styles/css_manager.dart';

class FloorTile extends StatelessWidget {
  const FloorTile({
    super.key, 
    required this.floorButton,
    this.onTap
  });

  final FloorButton floorButton;

  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: CSSManager.buttonDecoration(floorButton.isTarget),
        child: FittedBox(
          fit: BoxFit.contain,
          child: Text(
            floorButton.title,
            textAlign: TextAlign.center,
            style: TextStyle(color: floorButton.isTarget ? CSSManager.highlight : CSSManager.defaultBlack, fontSize: 48)
          )
        )
      )
    );
  }
}