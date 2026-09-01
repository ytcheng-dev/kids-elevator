import 'package:flutter/material.dart';

import '../models/board_button.dart';

import '../styles/css_manager.dart';

class DoorButton extends StatelessWidget {
  const DoorButton({
    super.key, 
    required this.actionButton,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerCancel,
    this.onTap,
    this.onLongPressStart,
    this.onLongPressEnd
  });

  final ActionButton actionButton;
  
  final VoidCallback? onPointerDown;
  final VoidCallback? onPointerUp;
  final VoidCallback? onPointerCancel;

  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  @override
  Widget build(BuildContext context) {
    return Listener(
      onPointerDown: (event) {onPointerDown?.call();},
      onPointerUp:(event) {onPointerUp?.call();},
      onPointerCancel: (event) {onPointerCancel?.call();},
      child: GestureDetector(
        onTap:() {onTap?.call();},
        onLongPressStart: (details) {onLongPressStart?.call();},
        onLongPressEnd: (details) {onLongPressEnd?.call();},
        child: Container(
          alignment: Alignment.center,
          padding: const EdgeInsets.all(10),
          decoration: CSSManager.buttonDecoration(actionButton.isPressed),
          child: RotatedBox(
            quarterTurns: 1,
            child: FittedBox(
              fit: BoxFit.contain,
              child: Icon(
                actionButton.iconCode,
                size: 60,
                color: actionButton.isPressed ? CSSManager.highlight : CSSManager.defaultBlack
              )
            )
          )
        ),
      )
    );
  }
}