import 'package:flutter/material.dart';

class CSSManager {
  static const Color backgroundGray = Color(0xFFCCC3CD);
  static const Color defaultBlack = Color(0xFF757382);
  static const Color highlight = Color(0xFFAD6777);
  static const Color screenText = Color(0xFFC35C5E);

  static const double shortSidePercent = 0.35;    // 按鈕的寬邊 (百分比)
  static const double longSidePercent = 0.18;   // 按鈕的長邊(百分比)

  static BoxDecoration buttonDecoration(bool isHighlight) {
    return BoxDecoration(
      color: backgroundGray,
      borderRadius: BorderRadius.circular(8),
      border: Border.all(
        color: isHighlight ? highlight : defaultBlack,
        width: 3
      )
    );
  }

  static SizedBox getButtonBox(Widget btn, double width) {
    return SizedBox(
      width: width,
      child: AspectRatio(
        aspectRatio: 1,
        child: btn
      )
    );
  }
}