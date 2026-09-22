import 'package:flutter/material.dart';

import '../../models/enums.dart';
import '../../models/panel_buttons.dart';

import '../../styles/layout_css.dart';

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

  final Color highlightColor = LayoutCss.secondary5,
                shadowColor = LayoutCss.neutral2;

  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final IconData iconCode = widget.actionButton.btnType == ActionType.open ? Icons.unfold_more_outlined : Icons.unfold_less_outlined;

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
              padding: LayoutCss.p2,
              decoration: BoxDecoration(
                color: _isPressed ? LayoutCss.secondary2 : LayoutCss.secondary0,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: _isPressed ? highlightColor : shadowColor
                ),
                boxShadow: [
                  _getShadow()
                ]
              ),
              child: RotatedBox(
                  quarterTurns: 1,
                  child: FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(iconCode,
                          size: 60,
                          color: _isPressed
                              ? highlightColor
                              : LayoutCss.text1)))),
        ));
  }
  BoxShadow _getShadow() {
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