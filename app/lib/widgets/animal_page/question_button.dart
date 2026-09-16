import 'package:flutter/material.dart';

import '../../styles/layout_css.dart';

class QuestionButton extends StatefulWidget{
  const QuestionButton ({
    super.key,
    required this.animalImg,
    this.isShining = false,
    this.onTap
  });

  final String animalImg;
  final VoidCallback? onTap;
  final bool isShining;

  @override
  State<QuestionButton> createState() => _QuestionButtonState();
}

class _QuestionButtonState extends State<QuestionButton>  with SingleTickerProviderStateMixin{
  _QuestionButtonState();

  bool isPressed = false;

  late final AnimationController _quesAnimateController;

  late final Animation<Color?> _quesAnimateBorder;


  @override
  void initState() {
    super.initState();

    _quesAnimateController = AnimationController(vsync: this, duration: const Duration(milliseconds: 500));

    _quesAnimateBorder = ColorTween(
      begin: LayoutCss.secondary,
      end: LayoutCss.secondary1
    ).animate(_quesAnimateController);

    if (widget.isShining) {
      _quesAnimateController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _quesAnimateController.dispose();

    super.dispose();
  }

  @override
  void didUpdateWidget(covariant QuestionButton oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.isShining != widget.isShining) {
      if (widget.isShining) {
        _quesAnimateController.repeat(reverse: true);
      }
      else {
        _quesAnimateController.stop();
        _quesAnimateController.reset();
      }
    }
  }

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
      child: Stack(
          children: <Widget>[
            AnimatedBuilder(
              animation: _quesAnimateController,
              builder: (context, child) {
                return Container(
                  padding: LayoutCss.m1,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                    border: Border.all(
                      color: _quesAnimateBorder.value!,
                      width: 3
                    ),
                    boxShadow: [_getBoxShadow(isPressed)]
                  ),
                  child: child
                );
              },
              child: Container(
                decoration: const BoxDecoration(
                  color: LayoutCss.defaultBG,
                  shape: BoxShape.circle
                ),
                child: FittedBox(
                  fit: BoxFit.contain,
                  child: Image(image: AssetImage(widget.animalImg))
                )  
              )
            ),
            Positioned.fill(
              child: Align(
                alignment: Alignment.bottomRight,
                child: FractionallySizedBox(
                  widthFactor: 0.35,
                  heightFactor: 0.35,
                  child: AnimatedBuilder(
                    animation: _quesAnimateController,
                    builder: (context, child) {
                      return Container(
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  border: Border.all(
                                    color: Colors.white,
                                    width: 2
                                  ),
                                  color: _quesAnimateBorder.value!
                                ),
                                child: child
                      );
                    },
                    child: const FittedBox(
                      fit: BoxFit.contain,
                      child: Icon(
                        Icons.volume_up,
                        size: 48,
                        color: Colors.white
                      )
                    )
                  )
                )
              )
            )
          ]
        )
    );
  }
}

BoxShadow _getBoxShadow(bool isPressed) {
  return isPressed ? const BoxShadow(
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