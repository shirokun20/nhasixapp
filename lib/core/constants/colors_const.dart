import 'package:flutter/material.dart';

/// Color constants for the application
/// Designed for eye comfort and reduced strain during extended usage
class ColorsConst {
  // ===== EXISTING COLORS (Maintained for compatibility) =====
  static const Color primaryColor = Color(0xff1f1f1f);
  static const Color secondaryColor = Color(0xfffdfdfd);
  static const Color thirdColor = Color.fromARGB(255, 54, 54, 54);
  static const Color primaryTextColor = secondaryColor;
  static const Color secondaryTextColor = primaryColor;
  static const Color redCustomColor = Color(0xffea2853);

  // ===== DARK THEME COLORS (Eye-friendly & Performance optimized) =====

  /// Background Colors - Optimized for OLED displays and eye comfort
  static const Color darkBackground =
      Color(0xFF0D1117); // GitHub dark background
  static const Color darkSurface =
      Color(0xFF161B22); // Slightly lighter surface
  static const Color darkCard = Color(0xFF21262D); // Card background
  static const Color darkElevated = Color(0xFF2D333B); // Elevated surfaces

  /// Text Colors - High contrast but not harsh
  static const Color darkTextPrimary =
      Color(0xFFF0F6FC); // Primary text (white-ish)
  static const Color darkTextSecondary =
      Color(0xFF8B949E); // Secondary text (gray)
  static const Color darkTextTertiary =
      Color(0xFF6E7681); // Tertiary text (dimmer gray)
  static const Color darkTextDisabled = Color(0xFF484F58); // Disabled text

  /// Accent Colors - Vibrant but not overwhelming
  static const Color accentBlue = Color(0xFF58A6FF); // GitHub blue
  static const Color accentGreen = Color(0xFF3FB950); // Success green
  static const Color accentYellow = Color(0xFFD29922); // Yellow accent
  static const Color accentOrange = Color(0xFFD29922); // Warning orange
  static const Color accentRed = Color(0xFFF85149); // Error red
  static const Color accentPurple = Color(0xFFA5A2FF); // Purple accent
  static const Color accentPink =
      Color(0xFFFF7B72); // Pink accent (for favorites)

  /// Interactive Colors - Subtle but clear feedback
  static const Color hoverColor = Color(0xFF30363D); // Hover state
  static const Color pressedColor = Color(0xFF21262D); // Pressed state
  static const Color selectedColor = Color(0xFF1C2128); // Selected state
  static const Color focusColor = Color(0xFF388BFD); // Focus outline

  /// Border Colors - Subtle separation
  static const Color borderDefault = Color(0xFF30363D); // Default border
  static const Color borderMuted = Color(0xFF21262D); // Muted border
  static const Color borderSubtle = Color(0xFF1C2128); // Very subtle border

  /// Status Colors - Clear visual feedback
  static const Color successBackground =
      Color(0xFF0D1117); // Success background
  static const Color successBorder = Color(0xFF2EA043); // Success border
  static const Color warningBackground =
      Color(0xFF1C1A10); // Warning background
  static const Color warningBorder = Color(0xFFBF8700); // Warning border
  static const Color errorBackground = Color(0xFF1A1212); // Error background
  static const Color errorBorder = Color(0xFFDA3633); // Error border

  // ===== LIGHT THEME COLORS (For future light mode support) =====

  /// Light Background Colors
  static const Color lightBackground = Color(0xFFFFFFFF); // Pure white
  static const Color lightSurface = Color(0xFFF6F8FA); // Light gray surface
  static const Color lightCard = Color(0xFFFFFFFF); // Card background
  static const Color lightElevated = Color(0xFFF6F8FA); // Elevated surfaces

  /// Light Text Colors
  static const Color lightTextPrimary =
      Color(0xFF24292F); // Primary text (dark)
  static const Color lightTextSecondary = Color(0xFF656D76); // Secondary text
  static const Color lightTextTertiary = Color(0xFF8C959F); // Tertiary text
  static const Color lightTextDisabled = Color(0xFFD0D7DE); // Disabled text

  // ===== SEMANTIC COLORS (Context-specific) =====

  /// Content Rating Colors (for NSFW indicators)
  static const Color ratingGeneral = Color(0xFF3FB950); // Green for general
  static const Color ratingMature = Color(0xFFD29922); // Orange for mature
  static const Color ratingExplicit = Color(0xFFF85149); // Red for explicit

  /// Tag Category Colors (for different tag types)
  static const Color tagArtist = Color(0xFF58A6FF); // Blue for artists
  static const Color tagCharacter = Color(0xFFA5A2FF); // Purple for characters
  static const Color tagParody = Color(0xFF3FB950); // Green for parodies
  static const Color tagGroup = Color(0xFFD29922); // Orange for groups
  static const Color tagLanguage = Color(0xFFFF7B72); // Pink for languages
  static const Color tagCategory = Color(0xFF8B949E); // Gray for categories

  /// Download Status Colors
  static const Color downloadPending = Color(0xFF8B949E); // Gray for pending
  static const Color downloadProgress =
      Color(0xFF58A6FF); // Blue for downloading
  static const Color downloadComplete =
      Color(0xFF3FB950); // Green for completed
  static const Color downloadError = Color(0xFFF85149); // Red for errors
  static const Color downloadPaused = Color(0xFFD29922); // Orange for paused

  /// Reading Progress Colors
  static const Color progressUnread = Color(0xFF30363D); // Gray for unread
  static const Color progressReading =
      Color(0xFF58A6FF); // Blue for currently reading
  static const Color progressCompleted =
      Color(0xFF3FB950); // Green for completed

  // ===== GRADIENT COLORS (For visual appeal) =====

  /// Subtle gradients for cards and surfaces
  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF21262D),
      Color(0xFF1C2128),
    ],
  );

  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      Color(0xFF58A6FF),
      Color(0xFFA5A2FF),
    ],
  );

  // ===== UTILITY METHODS =====

  /// Get color with opacity for overlays
  static Color withOpacity(Color color, double opacity) {
    return color.withValues(alpha: opacity);
  }

  /// Get appropriate text color based on background
  static Color getTextColorForBackground(Color backgroundColor) {
    // Calculate luminance to determine if background is light or dark
    final luminance = backgroundColor.computeLuminance();
    return luminance > 0.5 ? lightTextPrimary : darkTextPrimary;
  }

  /// Get tag color based on tag type
  static Color getTagColor(String tagType) {
    switch (tagType.toLowerCase()) {
      case 'artist':
        return tagArtist;
      case 'character':
        return tagCharacter;
      case 'parody':
        return tagParody;
      case 'group':
        return tagGroup;
      case 'language':
        return tagLanguage;
      case 'category':
        return tagCategory;
      default:
        return darkTextSecondary;
    }
  }

  /// Get download status color
  static Color getDownloadStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return downloadPending;
      case 'downloading':
      case 'progress':
        return downloadProgress;
      case 'completed':
      case 'complete':
        return downloadComplete;
      case 'error':
      case 'failed':
        return downloadError;
      case 'paused':
        return downloadPaused;
      default:
        return downloadPending;
    }
  }

  /// Get reading progress color
  static Color getReadingProgressColor(String status) {
    switch (status.toLowerCase()) {
      case 'unread':
        return progressUnread;
      case 'reading':
      case 'current':
        return progressReading;
      case 'completed':
      case 'finished':
        return progressCompleted;
      default:
        return progressUnread;
    }
  }

  // ===== MATERIAL DESIGN 3 COLORS (For consistency with Flutter widgets) =====

  /// Primary colors
  static const Color primary = accentBlue;
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color primaryContainer = Color(0xFF1C2128);
  static const Color onPrimaryContainer = accentBlue;

  /// Secondary colors
  static const Color secondary = Color(0xFF8B949E);
  static const Color onSecondary = Color(0xFF24292F);
  static const Color secondaryContainer = Color(0xFF30363D);
  static const Color onSecondaryContainer = Color(0xFFF0F6FC);

  /// Surface colors
  static const Color surface = darkSurface;
  static const Color onSurface = darkTextPrimary;
  static const Color surfaceVariant = darkCard;
  static const Color onSurfaceVariant = darkTextSecondary;

  /// Background colors
  static const Color background = darkBackground;
  static const Color onBackground = darkTextPrimary;

  /// Error colors
  static const Color error = accentRed;
  static const Color onError = Color(0xFFFFFFFF);
  static const Color errorContainer = errorBackground;
  static const Color onErrorContainer = accentRed;

  /// Additional semantic colors for widgets
  static const Color success = accentGreen;
  static const Color onSuccess = Color(0xFFFFFFFF);
  static const Color warning = accentOrange;
  static const Color onWarning = Color(0xFF24292F);
  static const Color info = accentBlue;
  static const Color onInfo = Color(0xFFFFFFFF);

  /// Outline colors
  static const Color outline = borderDefault;
  static const Color outlineVariant = borderMuted;

  /// Inverse colors
  static const Color inverseSurface = lightSurface;
  static const Color onInverseSurface = lightTextPrimary;
  static const Color inversePrimary = Color(0xFF0969DA);
}
