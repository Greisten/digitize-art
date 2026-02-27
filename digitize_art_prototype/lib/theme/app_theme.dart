import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// App theme matching digitize.art website design
/// Colors: Dark brown #33271e, Purple #8640ae, Cream #F5F5F0
/// Fonts: Space Grotesk (headings), Inter (text)
class AppTheme {
  // Primary colors from digitize.art
  static const Color primaryMain = Color(0xFF33271E);
  static const Color primaryLight = Color(0xFF534031);
  static const Color primaryDark = Color(0xFF130E0B);
  
  // Secondary (accent purple)
  static const Color secondaryMain = Color(0xFF8640AE);
  static const Color secondaryLight = Color(0xFF9E5DC4);
  static const Color secondaryDark = Color(0xFF693289);
  
  // Accent (cream/beige)
  static const Color accentMain = Color(0xFFF5F5F0);
  static const Color accentLight = Color(0xFFFFFFFF);
  static const Color accentDark = Color(0xFFE1E1D1);
  
  // Functional colors
  static const Color successMain = Color(0xFF26A94C);
  static const Color errorMain = Color(0xFFED262D);
  
  // Text colors
  static const Color headingColor = Color(0xFF4A3728);
  static const Color textDarkBg = Color(0xFF9CA3AF);
  static const Color textDarkBgHeading = Color(0xFFF3F4F6);

  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      colorScheme: const ColorScheme.light(
        primary: primaryMain,
        secondary: secondaryMain,
        tertiary: accentMain,
        surface: accentLight,
        background: accentMain,
        error: errorMain,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: headingColor,
        onBackground: headingColor,
      ),
      
      scaffoldBackgroundColor: accentMain,
      
      // Typography - Space Grotesk for headings, Inter for body
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: headingColor,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: headingColor,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: headingColor,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: headingColor,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        titleMedium: GoogleFonts.spaceGrotesk(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        titleSmall: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: headingColor,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: headingColor,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: headingColor,
        ),
        bodySmall: GoogleFonts.inter(
          fontSize: 12,
          color: headingColor.withOpacity(0.7),
        ),
        labelLarge: GoogleFonts.spaceGrotesk(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      
      // Button theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryMain,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.spaceGrotesk(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryMain,
          side: const BorderSide(color: secondaryMain, width: 2),
          textStyle: GoogleFonts.spaceGrotesk(
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
      
      // Card theme
      cardTheme: CardTheme(
        color: accentLight,
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      
      // AppBar theme
      appBarTheme: AppBarTheme(
        backgroundColor: primaryMain,
        foregroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
      
      // Input decoration theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: accentLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryLight),
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
      
      // FloatingActionButton theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: secondaryMain,
        foregroundColor: Colors.white,
        elevation: 4,
      ),
    );
  }
  
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      colorScheme: const ColorScheme.dark(
        primary: secondaryLight,
        secondary: secondaryMain,
        tertiary: accentMain,
        surface: primaryDark,
        background: primaryMain,
        error: errorMain,
        onPrimary: Colors.white,
        onSecondary: Colors.white,
        onSurface: textDarkBgHeading,
        onBackground: textDarkBgHeading,
      ),
      
      scaffoldBackgroundColor: primaryMain,
      
      textTheme: TextTheme(
        displayLarge: GoogleFonts.spaceGrotesk(
          fontSize: 57,
          fontWeight: FontWeight.bold,
          color: textDarkBgHeading,
        ),
        displayMedium: GoogleFonts.spaceGrotesk(
          fontSize: 45,
          fontWeight: FontWeight.bold,
          color: textDarkBgHeading,
        ),
        displaySmall: GoogleFonts.spaceGrotesk(
          fontSize: 36,
          fontWeight: FontWeight.bold,
          color: textDarkBgHeading,
        ),
        headlineLarge: GoogleFonts.spaceGrotesk(
          fontSize: 32,
          fontWeight: FontWeight.bold,
          color: textDarkBgHeading,
        ),
        headlineMedium: GoogleFonts.spaceGrotesk(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
        headlineSmall: GoogleFonts.spaceGrotesk(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
        titleLarge: GoogleFonts.spaceGrotesk(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
        bodyLarge: GoogleFonts.inter(
          fontSize: 16,
          color: textDarkBg,
        ),
        bodyMedium: GoogleFonts.inter(
          fontSize: 14,
          color: textDarkBg,
        ),
      ),
      
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: secondaryMain,
          foregroundColor: Colors.white,
          textStyle: GoogleFonts.spaceGrotesk(
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
        backgroundColor: primaryDark,
        foregroundColor: textDarkBgHeading,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: GoogleFonts.spaceGrotesk(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: textDarkBgHeading,
        ),
      ),
    );
  }
}
