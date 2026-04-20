import 'package:flutter/material.dart';

/// Design tokens for the example app.
/// Map Figma color/spacing/radius variables to these constants.
class AppTokens {
  AppTokens._();

  // Colors — align with Material 3 / Figma variables
  static const Color primary = Color(0xFF4F46E5);
  static const Color success = Color(0xFF059669);
  static const Color error = Color(0xFFDC2626);
  static const Color successSurface = Color(0xFFECFDF5);
  static const Color errorSurface = Color(0xFFFEF2F2);
  static const Color successOnSurface = Color(0xFF065F46);
  static const Color errorOnSurface = Color(0xFF991B1B);

  // Spacing (align with Figma spacing scale)
  static const double spaceXs = 4;
  static const double spaceSm = 8;
  static const double spaceMd = 12;
  static const double spaceLg = 16;
  static const double spaceXl = 24;

  // Radius
  static const double radiusSm = 4;
  static const double radiusMd = 8;
  static const double radiusLg = 12;
}
