import 'package:flutter/material.dart';

import '../styles/layout_css.dart';

class BackLeading extends StatelessWidget {
  const BackLeading({super.key, this.onPressed});

  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
    icon: const Icon(Icons.home),
    style: IconButton.styleFrom(
      foregroundColor: LayoutCss.primary7,
      backgroundColor: LayoutCss.secondary0,
      shape: const CircleBorder(),
      elevation: 6,
      // side: const BorderSide(color: LayoutCss.neutral2)
    ),
    onPressed: () {
      onPressed?.call();
    }
  );
  }
}