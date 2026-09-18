import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'screens/home_page.dart';

import 'styles/layout_css.dart';

void main() {
  runApp(
    const ProviderScope(child: MyApp())
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Kid\'s Elevator',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: const ColorScheme(
          brightness: Brightness.light,
          primary: LayoutCss.primary,
          onPrimary: LayoutCss.primary9,      // 疊在 primary 上的文字/圖示
          secondary: LayoutCss.secondary,
          onSecondary: LayoutCss.secondary9,
          tertiary: LayoutCss.tertiary,
          onTertiary: LayoutCss.tertiary9,
          surface: LayoutCss.surface,
          onSurface: LayoutCss.text1,
          error: Colors.red,
          onError: Colors.white,
        ),
      ),
      home: const HomePage(),
    );
  }
}
