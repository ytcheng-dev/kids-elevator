import 'package:flutter/material.dart';

import '../../models/panel_buttons.dart';

import '../../styles/css_manager.dart';

class DoorButton extends StatefulWidget {
  const DoorButton(
      {super.key,
      required this.actionButton,
      this.onTap,
      this.onLongPressStart,
      this.onLongPressEnd});

  final ActionButton actionButton;

  final VoidCallback? onTap;
  final VoidCallback? onLongPressStart;
  final VoidCallback? onLongPressEnd;

  @override
  State<DoorButton> createState() {
    return _DoorButtonState();
  }
}

class _DoorButtonState extends State<DoorButton> {
  _DoorButtonState();

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return Listener(
        onPointerDown: (event) {
          setState(() {
            _isPressed = true;
          });
        },
        onPointerUp: (event) {
          setState(() {
            _isPressed = false;
          });
        },
        onPointerCancel: (event) {
          setState(() {
            _isPressed = false;
          });
        },
        child: GestureDetector(
          onTap: () {
            widget.onTap?.call();
          },
          onLongPressStart: (details) {
            widget.onLongPressStart?.call();
          },
          onLongPressEnd: (details) {
            widget.onLongPressEnd?.call();
          },
          child: Container(
              alignment: Alignment.center,
              padding: const EdgeInsets.all(10),
              decoration: CSSManager.buttonDecoration(_isPressed),
              child: RotatedBox(
                  quarterTurns: 1,
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(widget.actionButton.iconCode,
                          size: 60,
                          color: _isPressed
                              ? CSSManager.highlight
                              : CSSManager.defaultBlack)))),
        ));
  }
}