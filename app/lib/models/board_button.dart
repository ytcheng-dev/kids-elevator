import 'package:flutter/material.dart';

import 'enums.dart';

/// 樓層按鈕
class FloorButton {
    FloorButton({required this.title});  // contructer

    final String title;
    bool isTarget = false;  // 初始為未選取
}

/// 開/關門按紐
class ActionButton {
  // constructor
  ActionButton({required this.title, required this.btnType, required this.iconCode});

  final String title;
  final IconData iconCode;
  final ActionType btnType;

  bool isPressed = false;
}