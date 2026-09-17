import 'package:flutter/material.dart';

class LayoutCss { 
  static const Color primary = Color(0xFF7FB685),
                     primary0 = Color(0xFFC5FFC9),
                     primary1 = Color(0xFFB7F1BB),
                     primary2 = Color(0xFF9CD4A1),
                     primary3 = Color(0xFF81B887),
                     primary4 = Color(0xFF679D6E),
                     primary5 = Color(0xFF4E8356),
                     primary6 = Color(0xFF35693F),
                     primary7 = Color(0xFF1C5129),
                     primary8 = Color(0xFF003915),
                     primary9 = Color(0xFF002109);

  static const Color secondary = Color(0xFFF4A259),
                     secondary0 = Color(0xFFFFEDE2),
                     secondary1 = Color(0xFFFFDCC2),
                     secondary2 = Color(0xFFFFB77B),
                     secondary3 = Color(0xFFE99951),
                     secondary4 = Color(0xFFCA7F3A),
                     secondary5 = Color(0xFFAC6622),
                     secondary6 = Color(0xFF8E4E08),
                     secondary7 = Color(0xFF6D3A00),
                     secondary8 = Color(0xFF4C2700),
                     secondary9 = Color(0xFF2E1500);

  static const Color tertiary = Color(0xFFE8998D),
                     tertiary0 = Color(0xFFFFEDEA),
                     tertiary1 = Color(0xFFFFDAD5),
                     tertiary2 = Color(0xFFFFB4A8),
                     tertiary3 = Color(0xFFE6978B),
                     tertiary4 = Color(0xFFC77D72),
                     tertiary5 = Color(0xFFA9645A),
                     tertiary6 = Color(0xFF8C4D43),
                     tertiary7 = Color(0xFF70362D),
                     tertiary8 = Color(0xFF542019),
                     tertiary9 = Color(0xFF390C07);

  static const neutral = Color(0xFF4A4238),
               neutral0 = Color(0xFFFCEFE0),
               neutral1 = Color(0xFFEEE0D2),
               neutral2 = Color(0xFFD1C5B7),
               neutral3 = Color(0xFFB5A99D),
               neutral4 = Color(0xFF9A8F83),
               neutral5 = Color(0xFF7F756A),
               neutral6 = Color(0xFF665D52),
               neutral7 = Color(0xFF4E453B),
               neutral8 = Color(0xFF362F26),
               neutral9 = Color(0xFF211B12);

  static const Color defaultBG = neutral0,   // 主背景色
                     surface = neutral1,     // 面板色
                     surfaceBorder = neutral3,
                     text1 = neutral5,       // 主要文字
                     text2 = neutral6;       // 次要文字

  // 文字大小
  static double textSizeBase = 0;

  static double get h1 => textSizeBase * 2;
  static double get h2 => textSizeBase * 1.75;
  static double get h3 => textSizeBase * 1.5;
  static double get h4 => textSizeBase * 1.25;
  static double get h5 => textSizeBase * 1;
  static double get h6 => textSizeBase * 0.75;

  // margin, padding
  static double marginBase = 0;

  static EdgeInsets get m1 => EdgeInsets.all(marginBase);
  static EdgeInsets get m2 => EdgeInsets.all(marginBase * 2);
  static EdgeInsets get m3 => EdgeInsets.all(marginBase * 3);
  static EdgeInsets get mt1 => EdgeInsets.only(top: marginBase);
  static EdgeInsets get mt2 => EdgeInsets.only(top: marginBase * 2);
  static EdgeInsets get mt3 => EdgeInsets.only(top: marginBase * 3);
  static EdgeInsets get mb1 => EdgeInsets.only(bottom: marginBase);
  static EdgeInsets get mb2 => EdgeInsets.only(bottom: marginBase * 2);
  static EdgeInsets get mb3 => EdgeInsets.only(bottom: marginBase * 3);

  static EdgeInsets get p1 => EdgeInsets.all(marginBase);
  static EdgeInsets get p2 => EdgeInsets.all(marginBase * 2);
  static EdgeInsets get p3 => EdgeInsets.all(marginBase * 3);
  static EdgeInsets get pt1 => EdgeInsets.only(top: marginBase);
  static EdgeInsets get pt2 => EdgeInsets.only(top: marginBase * 2);
  static EdgeInsets get pt3 => EdgeInsets.only(top: marginBase * 3);
  static EdgeInsets get pb1 => EdgeInsets.only(bottom: marginBase);
  static EdgeInsets get pb2 => EdgeInsets.only(bottom: marginBase * 2);
  static EdgeInsets get pb3 => EdgeInsets.only(bottom: marginBase * 3);
}