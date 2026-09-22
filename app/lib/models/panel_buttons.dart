import 'package:flutter/material.dart';

import 'enums.dart';

/// 樓層按鈕
class FloorButton {
  FloorButton({required this.title, required this.audioFile}); // contructer

  final String title;
  final String audioFile;

  bool isTarget = false; // 初始為未選取
}

/// 開/關門按紐
class ActionButton {
  // constructor
  ActionButton(
      {required this.title,
      required this.btnType,
      required this.audioFile});

  final String title;
  final String audioFile;
  final ActionType btnType;
}
