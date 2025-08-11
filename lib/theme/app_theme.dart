import 'package:flutter/material.dart';

class AppTheme {
  static ThemeData build() {
    final Color seed = const Color(0xFF6750A4);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.light,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(centerTitle: true),
      textTheme: Typography.blackMountainView.copyWith(
        displaySmall: const TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedColor: scheme.secondaryContainer,
        secondarySelectedColor: scheme.tertiaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }

  static ThemeData buildDark() {
    final Color seed = const Color(0xFF6750A4);
    final ColorScheme scheme = ColorScheme.fromSeed(
      seedColor: seed,
      brightness: Brightness.dark,
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      appBarTheme: const AppBarTheme(centerTitle: true),
      textTheme: Typography.whiteMountainView.copyWith(
        displaySmall: const TextStyle(fontWeight: FontWeight.w700),
        headlineSmall: const TextStyle(fontWeight: FontWeight.w600),
        titleMedium: const TextStyle(fontWeight: FontWeight.w600),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 46),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      cardTheme: CardTheme(
        elevation: 1,
        margin: const EdgeInsets.symmetric(vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        selectedColor: scheme.secondaryContainer,
        secondarySelectedColor: scheme.tertiaryContainer,
        labelStyle: TextStyle(color: scheme.onSurface),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorColor: scheme.secondaryContainer,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      ),
    );
  }
}


