import 'package:flutter/material.dart';

import 'app_colors.dart';

/// 全局主题：暖橙马卡龙、大圆角、卡通温馨。
/// 所有页面通过 Theme.of(context) 取色，禁止再散落硬编码。
class AppTheme {
  AppTheme._();

  static const double radiusCard = 26; // 对齐 Demo --r-lg:26px
  static const double radiusButton = 18;
  static const double radiusChip = 14;

  static ThemeData get light {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: Brightness.light,
      primary: AppColors.primaryDeep,
      onPrimary: Colors.white,
      secondary: AppColors.mint,
      surface: AppColors.card,
      onSurface: AppColors.ink,
      surfaceTint: Colors.transparent,
    );

    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: AppColors.bg,
      brightness: Brightness.light,
      fontFamily: 'Roboto',
    );

    return base.copyWith(
      textTheme: _textTheme(base.textTheme),
      appBarTheme: const AppBarTheme(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        foregroundColor: AppColors.ink,
        titleTextStyle: TextStyle(
          color: AppColors.ink,
          fontSize: 20,
          fontWeight: FontWeight.w800,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.card,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusCard),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: AppColors.card,
        surfaceTintColor: Colors.transparent,
        indicatorColor: AppColors.primarySoft,
        elevation: 0,
        height: 68,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? AppColors.primaryDeep : AppColors.inkSoft,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: selected ? AppColors.primaryDeep : AppColors.inkSoft,
          );
        }),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 22),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.ink,
          side: const BorderSide(color: AppColors.line, width: 2),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 20),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusButton),
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primaryDeep,
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.skySoft,
        labelStyle: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.ink,
        ),
        side: BorderSide.none,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusChip),
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.card,
        hintStyle: const TextStyle(color: AppColors.inkSoft),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.line, width: 2),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.bg,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
      ),
      dividerTheme: const DividerThemeData(color: AppColors.line, thickness: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.ink.withValues(alpha: 0.95),
        contentTextStyle: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),
    );
  }

  /// V1 仅浅色；深色降级为浅色，保证暖橙风格一致。
  static ThemeData get dark => light;

  static TextTheme _textTheme(TextTheme base) {
    return base
        .apply(bodyColor: AppColors.ink, displayColor: AppColors.ink)
        .copyWith(
          titleLarge: base.titleLarge?.copyWith(fontWeight: FontWeight.w800),
          titleMedium: base.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          titleSmall: base.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          bodyLarge: base.bodyLarge?.copyWith(height: 1.5),
          bodyMedium: base.bodyMedium?.copyWith(height: 1.5),
          labelLarge: base.labelLarge?.copyWith(fontWeight: FontWeight.w700),
        );
  }
}
