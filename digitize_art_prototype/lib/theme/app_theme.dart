import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme following the LE LOFT — Studio Créatif brand guidelines.
/// Colours: Blue #0000EE, Red #EE0000, Yellow #FFE000 on white #FFFFFF with
/// black #000000 text. Typeface: Montserrat.
class AppTheme {
  // --- LE LOFT brand palette ---
  static const Color brandBlue = Color(0xFF0000EE);
  static const Color brandRed = Color(0xFFEE0000);
  static const Color brandYellow = Color(0xFFFFE000);
  static const Color brandWhite = Color(0xFFFFFFFF);
  static const Color brandBlack = Color(0xFF000000);

  // Primary = brand blue (lead interactive colour)
  static const Color primaryMain = brandBlue;
  static const Color primaryLight = Color(0xFF4D4DFF);
  static const Color primaryDark = Color(0xFF0000B3);

  // Secondary accent = brand blue too (keeps interactive elements coherent)
  static const Color secondaryMain = brandBlue;
  static const Color secondaryLight = Color(0xFF4D4DFF);
  static const Color secondaryDark = Color(0xFF0000B3);

  // Surfaces / background (white)
  static const Color accentMain = brandWhite;
  static const Color accentLight = brandWhite;
  static const Color accentDark = Color(0xFFF2F2F2);

  // Functional colours
  static const Color successMain = Color(0xFF26A94C);
  static const Color errorMain = brandRed; // brand red doubles as error

  // Text colours
  static const Color headingColor = brandBlack;
  static const Color textDarkBg = Color(0xFFB5B5B5);
  static const Color textDarkBgHeading = brandWhite;

  // Dark-theme neutral surfaces
  static const Color darkBg = Color(0xFF0E0E0E);
  static const Color darkSurface = Color(0xFF1A1A1A);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,

      colorScheme: const ColorScheme.light(
        primary: primaryMain,
        secondary: secondaryMain,
        tertiary: brandYellow,
        surface: brandWhite,
        error: errorMain,
        onPrimary: brandWhite,
        onSecondary: brandWhite,
        onTertiary: brandBlack,
        onSurface: brandBlack,
        onError: brandWhite,
      ),

      scaffoldBackgroundColor: brandWhite,

      // Typography — Montserrat throughout (bold headings, regular body).
      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: headingColor,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: headingColor,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: headingColor,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: headingColor,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        titleMedium: GoogleFonts.montserrat(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        titleSmall: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          color: headingColor,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          color: headingColor,
        ),
        bodySmall: GoogleFonts.montserrat(
          fontSize: 12,
          color: headingColor.withOpacity(0.7),
        ),
        labelLarge: GoogleFonts.montserrat(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryMain,
          foregroundColor: brandWhite,
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
        ),
      ),

      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryMain,
          side: const BorderSide(color: secondaryMain, width: 2),
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      cardTheme: CardTheme(
        color: brandWhite,
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: brandWhite,
        foregroundColor: brandBlack,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w700,
          color: brandBlack,
        ),
      ),

      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: brandWhite,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFFD0D0D0)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: secondaryMain, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: errorMain),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),

      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryMain,
        foregroundColor: brandWhite,
        elevation: 2,
      ),
    );
  }

  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,

      colorScheme: const ColorScheme.dark(
        primary: primaryLight,
        secondary: secondaryMain,
        tertiary: brandYellow,
        surface: darkSurface,
        error: errorMain,
        onPrimary: brandWhite,
        onSecondary: brandWhite,
        onTertiary: brandBlack,
        onSurface: textDarkBgHeading,
        onError: brandWhite,
      ),

      scaffoldBackgroundColor: darkBg,

      textTheme: TextTheme(
        displayLarge: GoogleFonts.montserrat(
          fontSize: 57,
          fontWeight: FontWeight.w700,
          color: textDarkBgHeading,
        ),
        displayMedium: GoogleFonts.montserrat(
          fontSize: 45,
          fontWeight: FontWeight.w700,
          color: textDarkBgHeading,
        ),
        displaySmall: GoogleFonts.montserrat(
          fontSize: 36,
          fontWeight: FontWeight.w700,
          color: textDarkBgHeading,
        ),
        headlineLarge: GoogleFonts.montserrat(
          fontSize: 32,
          fontWeight: FontWeight.w700,
          color: textDarkBgHeading,
        ),
        headlineMedium: GoogleFonts.montserrat(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
        headlineSmall: GoogleFonts.montserrat(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
        titleLarge: GoogleFonts.montserrat(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
        bodyLarge: GoogleFonts.montserrat(
          fontSize: 16,
          color: textDarkBg,
        ),
        bodyMedium: GoogleFonts.montserrat(
          fontSize: 14,
          color: textDarkBg,
        ),
      ),

      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryMain,
          foregroundColor: brandWhite,
          textStyle: GoogleFonts.montserrat(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),

      appBarTheme: AppBarTheme(
        backgroundColor: darkBg,
        foregroundColor: textDarkBgHeading,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.montserrat(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
      ),
    );
  }
}
