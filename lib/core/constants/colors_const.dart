import 'package:flutter/material.dart';

/// Brand colors extracted from Frame.svg
class AppColors {
  // Core brand colors
  static const Color brandCoral = Color(0xFFF1958E); // #F1958E - Main coral
  static const Color brandMuted = Color(0xFFE0827E); // #E0827E - Muted coral
  static const Color brandDusty = Color(0xFF9D555B); // #9D555B - Dusty rose
  static const Color brandDark = Color(0xFF1A1A1F); // #1A1A1F - Near black

  // Light theme - warm, elegant, readable
  static const Color lightBg = Color(0xFFFBF9F7); // Warm off-white
  static const Color lightSurface = Color(0xFFF3F0EC); // Cream
  static const Color lightCard = Color(0xFFFFFFFF); // Pure white
  static const Color lightElevated = Color(0xFFFAF8F5); // Slight warm tint
  static const Color lightBorder =
      Color.fromARGB(255, 255, 190, 105); // Warm gray
  static const Color lightText = Color(0xFF2C2926); // Warm black
  static const Color lightTextSub = Color(0xFF7A716A); // Muted brown

  // Dark theme - deep, rich, comfortable
  static const Color darkBg = Color(0xFF121215); // Deep dark
  static const Color darkSurface = Color(0xFF1A1A1F); // Surface from brand
  static const Color darkCard = Color(0xFF222228); // Slightly elevated
  static const Color darkElevated = Color(0xFF2A2A32); // Cards
  static const Color darkBorder =
      Color.fromARGB(255, 89, 55, 52); // Subtle borders
  static const Color darkText =
      Color.fromARGB(255, 255, 255, 255); // Warm white
  static const Color darkTextSub = Color(0xFF9A9590); // Muted

  // AMOLED - pure black, coral accents
  static const Color amoledBg = Color(0xFF000000); // Pure black
  static const Color amoledSurface = Color(0xFF0A0A0F); // Slight tint
  static const Color amoledCard = Color(0xFF141418); // Card
  static const Color amoledBorder = Color(0xFF282830); // Border

  // Semantic - derived from brand palette
  static const Color primary = brandCoral;
  static const Color primaryContainer = Color(0xFF4A2A28); // Dark coral bg
  static const Color onPrimaryContainer = Color(0xFFFFD8D4);

  static const Color secondary = brandDusty;
  static const Color secondaryContainer = Color(0xFF3D2022);
  static const Color onSecondaryContainer = Color(0xFFFFD8D4);

  static const Color tertiary = brandMuted;
  static const Color tertiaryContainer = Color(0xFF3A1E20);
  static const Color onTertiaryContainer = Color(0xFFFFD8D4);

  // Utility colors
  static const Color surfaceDim = Color(0xFF3A3A42);
  static const Color surfaceBright = Color(0xFFE8E4E0);

  // Status colors
  static const Color error = Color(0xFFFF6B6B);
  static const Color errorContainer = Color(0xFF4A1A1A);
  static const Color success = Color(0xFF7DD3A8);
  static const Color warning = Color(0xFFFFD076);
  static const Color info = Color(0xFF7BB8FF);
}

/// Backward compatibility wrapper
class ColorsConst {
  static const Color primaryColor = AppColors.brandCoral;
  static const Color secondaryColor = AppColors.brandMuted;
  static const Color tertiaryColor = AppColors.brandDusty;
  static const Color accentDark = AppColors.brandDark;

  // Legacy dark theme
  static const Color darkBackground = AppColors.darkBg;
  static const Color darkSurface = AppColors.darkSurface;
  static const Color darkCard = AppColors.darkCard;
  static const Color darkElevated = AppColors.darkElevated;
  static const Color darkTextPrimary = AppColors.darkText;
  static const Color darkTextSecondary = AppColors.darkTextSub;
  static const Color borderDefault = AppColors.darkBorder;

  // Legacy light theme
  static const Color lightBackground = AppColors.lightBg;
  static const Color lightSurface = AppColors.lightSurface;
  static const Color lightCard = AppColors.lightCard;
  static const Color lightTextPrimary = AppColors.lightText;
  static const Color lightTextSecondary = AppColors.lightTextSub;

  // Legacy accents
  static const Color accentBlue = AppColors.info;
  static const Color accentGreen = AppColors.success;
  static const Color accentYellow = AppColors.warning;
  static const Color accentOrange = AppColors.warning;
  static const Color accentRed = AppColors.error;
  static const Color accentPink = Color(0xFFFF8A9A);

  // Tag colors
  static const Color tagArtist = AppColors.info;
  static const Color tagCharacter = Color(0xFFC8A8FF);
  static const Color tagParody = AppColors.success;
  static const Color tagGroup = AppColors.warning;
  static const Color tagLanguage = Color(0xFFFF8A9A);
  static const Color tagCategory = AppColors.darkTextSub;

  // Download status
  static const Color downloadPending = AppColors.darkTextSub;
  static const Color downloadProgress = AppColors.info;
  static const Color downloadComplete = AppColors.success;
  static const Color downloadError = AppColors.error;
  static const Color downloadPaused = AppColors.warning;

  // Gradient
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.darkCard, AppColors.darkSurface],
  );
}
