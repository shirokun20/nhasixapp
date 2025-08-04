import 'package:flutter/material.dart';
import 'package:nhasixapp/core/constants/colors_const.dart';

/// Text style constants for consistent typography throughout the app
/// Updated to use new ColorsConst and provide semantic text styles
class TextStyleConst {
  // ===== WEIGHT-BASED STYLES (Existing - maintained for compatibility) =====

  static TextStyle styleLight({
    Color textColor = ColorsConst.darkTextPrimary,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w300,
      height: 1.4, // Better line height for readability
    );
  }

  static TextStyle styleRegular({
    Color textColor = ColorsConst.darkTextPrimary,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.normal,
      height: 1.4,
    );
  }

  static TextStyle styleMedium({
    Color textColor = ColorsConst.darkTextPrimary,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w500,
      height: 1.4,
    );
  }

  static TextStyle styleSemiBold({
    Color textColor = ColorsConst.darkTextPrimary,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w600,
      height: 1.4,
    );
  }

  static TextStyle styleBold({
    Color textColor = ColorsConst.darkTextPrimary,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w700,
      height: 1.4,
    );
  }

  static TextStyle styleExtraBold({
    Color textColor = ColorsConst.darkTextPrimary,
    double size = 14,
  }) {
    return TextStyle(
      fontSize: size,
      color: textColor,
      fontWeight: FontWeight.w800,
      height: 1.4,
    );
  }

  // ===== SEMANTIC STYLES (New - for specific UI components) =====

  /// Heading styles for titles and headers
  static TextStyle get headingLarge => styleBold(
        textColor: ColorsConst.darkTextPrimary,
        size: 24,
      );

  static TextStyle get headingMedium => styleSemiBold(
        textColor: ColorsConst.darkTextPrimary,
        size: 20,
      );

  static TextStyle get headingSmall => styleMedium(
        textColor: ColorsConst.darkTextPrimary,
        size: 18,
      );

  /// Body text styles for content
  static TextStyle get bodyLarge => styleRegular(
        textColor: ColorsConst.darkTextPrimary,
        size: 16,
      );

  static TextStyle get bodyMedium => styleRegular(
        textColor: ColorsConst.darkTextPrimary,
        size: 14,
      );

  static TextStyle get bodySmall => styleRegular(
        textColor: ColorsConst.darkTextSecondary,
        size: 12,
      );

  /// Caption and label styles
  static TextStyle get caption => styleLight(
        textColor: ColorsConst.darkTextSecondary,
        size: 12,
      );

  static TextStyle get label => styleMedium(
        textColor: ColorsConst.darkTextSecondary,
        size: 12,
      );

  static TextStyle get overline => styleRegular(
        textColor: ColorsConst.darkTextTertiary,
        size: 10,
      );

  // ===== COMPONENT-SPECIFIC STYLES =====

  /// Content card styles
  static TextStyle get contentTitle => styleSemiBold(
        textColor: ColorsConst.darkTextPrimary,
        size: 16,
      );

  static TextStyle get contentSubtitle => styleLight(
        textColor: ColorsConst.darkTextSecondary,
        size: 12,
      );

  static TextStyle get contentTag => styleRegular(
        textColor: ColorsConst.darkTextSecondary,
        size: 11,
      );

  /// Button styles
  static TextStyle get buttonLarge => styleMedium(
        textColor: ColorsConst.darkTextPrimary,
        size: 16,
      );

  static TextStyle get buttonMedium => styleMedium(
        textColor: ColorsConst.darkTextPrimary,
        size: 14,
      );

  static TextStyle get buttonSmall => styleMedium(
        textColor: ColorsConst.darkTextPrimary,
        size: 12,
      );

  /// Navigation styles
  static TextStyle get navigationLabel => styleMedium(
        textColor: ColorsConst.darkTextSecondary,
        size: 14,
      );

  static TextStyle get navigationActive => styleSemiBold(
        textColor: ColorsConst.accentBlue,
        size: 14,
      );

  /// Status and feedback styles
  static TextStyle get statusSuccess => styleMedium(
        textColor: ColorsConst.accentGreen,
        size: 14,
      );

  static TextStyle get statusWarning => styleMedium(
        textColor: ColorsConst.accentOrange,
        size: 14,
      );

  static TextStyle get statusError => styleMedium(
        textColor: ColorsConst.accentRed,
        size: 14,
      );

  /// Loading and placeholder styles
  static TextStyle get loadingText => styleRegular(
        textColor: ColorsConst.darkTextSecondary,
        size: 14,
      );

  static TextStyle get placeholderText => styleLight(
        textColor: ColorsConst.darkTextTertiary,
        size: 14,
      );

  // ===== UTILITY METHODS =====

  /// Get text style with custom color while maintaining other properties
  static TextStyle withColor(TextStyle baseStyle, Color color) {
    return baseStyle.copyWith(color: color);
  }

  /// Get text style with custom size while maintaining other properties
  static TextStyle withSize(TextStyle baseStyle, double size) {
    return baseStyle.copyWith(fontSize: size);
  }

  /// Get text style with opacity
  static TextStyle withOpacity(TextStyle baseStyle, double opacity) {
    return baseStyle.copyWith(
        color: baseStyle.color?.withValues(alpha: opacity));
  }

  /// Get appropriate text style based on context
  static TextStyle getContextualStyle({
    required String context,
    Color? customColor,
    double? customSize,
  }) {
    TextStyle baseStyle;

    switch (context.toLowerCase()) {
      case 'title':
      case 'heading':
        baseStyle = headingMedium;
        break;
      case 'subtitle':
        baseStyle = bodyMedium;
        break;
      case 'body':
      case 'content':
        baseStyle = bodyLarge;
        break;
      case 'caption':
      case 'meta':
        baseStyle = caption;
        break;
      case 'button':
        baseStyle = buttonMedium;
        break;
      case 'tag':
        baseStyle = contentTag;
        break;
      case 'error':
        baseStyle = statusError;
        break;
      case 'success':
        baseStyle = statusSuccess;
        break;
      case 'warning':
        baseStyle = statusWarning;
        break;
      default:
        baseStyle = bodyMedium;
    }

    // Apply custom modifications if provided
    if (customColor != null) {
      baseStyle = withColor(baseStyle, customColor);
    }
    if (customSize != null) {
      baseStyle = withSize(baseStyle, customSize);
    }

    return baseStyle;
  }
}
