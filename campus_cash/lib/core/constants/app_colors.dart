import 'package:flutter/material.dart';

class AppColors {
  // Primary Palette - Deep Teal / Emerald for CashMate
  static const Color jade = Color(0xFF0B8F63); // --jade Primary Brand Jade
  static const Color primary = jade;
  static const Color primaryLight = Color(0xFF14B8A6);
  static const Color primaryDark = Color(0xFF076646);
  static const Color primaryContainer = Color(0xFFE2F3EC);

  // Secondary & Accents
  static const Color secondary = Color(0xFF4B3FD6); // --dig Vibrant Indigo / Secondary
  static const Color secondaryLight = Color(0xFF818CF8); // Indigo 400
  static const Color secondaryContainer = Color(0xFFECEAFE); // --dig-bg Lavender 100

  // Background & Surfaces
  static const Color bgTop = Color(0xFFB4E6CD); // --bgtop Mint Gradient Top
  static const Color bg = Color(0xFFDDF3E7); // --bg Soft Mint Sage Page Background
  static const Color background = bg;
  static const Color card = Colors.white; // --card Card Fill
  static const Color surface = card;
  static const Color surfaceVariant = Color(0xFFF6FAF8); // --field
  static const Color field = Color(0xFFF6FAF8); // --field Input background

  // Typography & Borders
  static const Color ink = Color(0xFF10201B); // --ink Primary Headings & Text
  static const Color textPrimary = ink;
  static const Color mute = Color(0xFF46594F); // --mute Secondary Text & Icons
  static const Color textSecondary = mute;
  static const Color textMuted = Color(0xFF8FA59C);
  static const Color line = Color(0xFFDCE6E1); // --line Subtle Borders & Dividers
  static const Color border = line;
  static const Color divider = line;

  // Visual Accents (Cash & Digital tiles)
  static const Color cash = Color(0xFFF2A516); // --cash Warm Gold
  static const Color amber = Color(0xFF9A6500); // --amber Text / Icon
  static const Color cashColor = amber; // Tile 1 icon color
  static const Color cashBg = Color(0xFFFFF4DC); // --cash-bg Warm Gold Tile
  static const Color dig = Color(0xFF4B3FD6); // --dig Vibrant Indigo
  static const Color digitalColor = dig;
  static const Color digitalBg = Color(0xFFECEAFE); // --dig-bg Lavender Tile
  static const Color red = Color(0xFFD64545); // --red Error & Warning
  static const Color redBg = Color(0xFFFDECEC); // --red-bg Warning / Cancelled Background
  static const Color okBg = Color(0xFFE2F5EC); // --ok-bg Success / Completed Background

  // Password strength meter colors
  static const List<Color> strengthColors = [
    Color(0xFFD64545), // Red
    Color(0xFFF2A516), // Amber
    Color(0xFF9BC53D), // Lime
    Color(0xFF0B8F63), // Jade
  ];

  // Status Colors
  static const Color statusSearching = Color(0xFFD97706);
  static const Color statusSearchingBg = Color(0xFFFEF3C7);
  static const Color statusMatched = Color(0xFF2563EB);
  static const Color statusMatchedBg = Color(0xFFDBEAFE);
  static const Color statusAccepted = Color(0xFF7C3AED);
  static const Color statusAcceptedBg = Color(0xFFEDE9FE);
  static const Color statusCompleted = Color(0xFF0B8F63);
  static const Color statusCompletedBg = Color(0xFFE2F3EC);
  static const Color statusCancelled = Color(0xFFD64545);
  static const Color statusCancelledBg = Color(0xFFFEE2E2);
  static const Color statusExpired = Color(0xFF6B7280);
  static const Color statusExpiredBg = Color(0xFFF3F4F6);
}
