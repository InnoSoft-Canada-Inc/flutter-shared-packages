import 'package:flutter/material.dart';

import 'app_tokens.dart';

/// Application theme using design tokens.
class AppTheme {
  AppTheme._();

  /// Light theme for the Payment Key sample app.
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: AppTokens.primary,
        brightness: Brightness.light,
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: AppTokens.spaceLg,
            vertical: AppTokens.spaceMd,
          ),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppTokens.spaceMd,
          vertical: AppTokens.spaceSm,
        ),
      ),
    );
  }
}
