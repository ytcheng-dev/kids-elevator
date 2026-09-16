import 'package:flutter/material.dart';

import '../../styles/layout_css.dart';

class QuestionButton extends StatefulWidget {
  const QuestionButton ({
    super.key,
    this.onTap
  });

  final VoidCallback? onTap;

  @override
  State<QuestionButton> createState() => _QuestionButtonState();
}

class _QuestionButtonState extends State<QuestionButton> {
  _QuestionButtonState();

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
        margin: LayoutCss.m3,
        alignment: Alignment.center,
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: const Color(0xFFCA7F3A),
          borderRadius: BorderRadius.circular(8),
          boxShadow: isPressed ? 
            const [BoxShadow(
              color: Color(0xFF4C2700),
              offset: Offset(0,1),
              blurRadius: 1
            )]
           : 
            const [BoxShadow(
              color: Color(0xFF4C2700),
              offset: Offset(0,5),
              blurRadius: 3
            )]
        ),
        child: const FittedBox(
          fit: BoxFit.contain,
          child: Icon(
            Icons.volume_up,
            size: 48,
            color: Colors.white
          )
        )
      )
    );
  }
}