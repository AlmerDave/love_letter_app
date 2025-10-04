// lib/utils/theme.dart
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // Color Palette
  static const Color primaryLavender = Color(0xFFE6E6FA);
  static const Color blushPink = Color(0xFFFFB6C1);
  static const Color softBlush = Color(0xFFFFC0CB); // ✅ NEW: Soft blush pink
  static const Color warmCream = Color(0xFFFFF8DC);
  static const Color softGold = Color(0xFFFFD700);
  static const Color deepPurple = Color(0xFF6A5ACD);
  static const Color darkText = Color(0xFF2C2C54);
  static const Color lightText = Color(0xFF6C5CE7);

  // Gradient Definitions
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primaryLavender, blushPink],
  );

  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [softGold, Color(0xFFFFE55C)],
  );

  static const LinearGradient cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFFFF0), warmCream],
  );

  // Theme Data
  static ThemeData get lightTheme {
    return ThemeData(
      primarySwatch: _createMaterialColor(deepPurple),
      primaryColor: deepPurple,
      scaffoldBackgroundColor: const Color(0xFFFAF6F7),
      
      // Beautiful Google Fonts Typography
      textTheme: GoogleFonts.merriweatherTextTheme().copyWith(
        displayLarge: GoogleFonts.merriweather(
          color: darkText,
          fontSize: 32,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
        ),
        displayMedium: GoogleFonts.merriweather(
          color: darkText,
          fontSize: 24,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.25,
        ),
        displaySmall: GoogleFonts.merriweather(
          color: darkText,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        headlineLarge: GoogleFonts.merriweather(
          color: darkText,
          fontSize: 18,
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: GoogleFonts.merriweather(
          color: lightText,
          fontSize: 16,
          fontWeight: FontWeight.w500,
        ),
        bodyLarge: GoogleFonts.merriweather(
          color: darkText,
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.5,
        ),
        bodyMedium: GoogleFonts.merriweather(
          color: darkText,
          fontSize: 14,
          fontWeight: FontWeight.normal,
          height: 1.4,
        ),
        bodySmall: GoogleFonts.merriweather(
          color: lightText,
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        labelLarge: GoogleFonts.merriweather(
          color: Colors.white,
          fontSize: 16,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      
      // App Bar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: deepPurple),
        titleTextStyle: GoogleFonts.merriweather(
          color: deepPurple,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),

      // Card Theme - Removed for compatibility
      // cardTheme: will be handled by individual Card widgets

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 4,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(25),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          textStyle: GoogleFonts.merriweather(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          textStyle: GoogleFonts.merriweather(
            fontSize: 14,
            fontWeight: FontWeight.w500,
          ),
        ),
      ),

      // Icon Theme
      iconTheme: const IconThemeData(
        color: deepPurple,
        size: 24,
      ),
    );
  }

  // Helper method to create MaterialColor from Color
  static MaterialColor _createMaterialColor(Color color) {
    List strengths = <double>[.05];
    Map<int, Color> swatch = {};
    final int r = color.red, g = color.green, b = color.blue;

    for (int i = 1; i < 10; i++) {
      strengths.add(0.1 * i);
    }
    for (var strength in strengths) {
      final double ds = 0.5 - strength;
      swatch[(strength * 1000).round()] = Color.fromRGBO(
        r + ((ds < 0 ? r : (255 - r)) * ds).round(),
        g + ((ds < 0 ? g : (255 - g)) * ds).round(),
        b + ((ds < 0 ? b : (255 - b)) * ds).round(),
        1,
      );
    }
    return MaterialColor(color.value, swatch);
  }

  // Custom Button Styles
  static ButtonStyle get acceptButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.green.shade400,
    foregroundColor: Colors.white,
    elevation: 6,
    shadowColor: Colors.green.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
  );

  static ButtonStyle get rejectButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: Colors.red.shade300,
    foregroundColor: Colors.white,
    elevation: 6,
    shadowColor: Colors.red.withOpacity(0.3),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(30),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 16),
  );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
    backgroundColor: primaryLavender,
    foregroundColor: deepPurple,
    elevation: 4,
    shadowColor: deepPurple.withOpacity(0.2),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(25),
    ),
    padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
  );

  // Custom Decorations
  static BoxDecoration get letterCardDecoration => BoxDecoration(
    gradient: cardGradient,
    borderRadius: BorderRadius.circular(20),
    boxShadow: [
      BoxShadow(
        color: deepPurple.withOpacity(0.15),
        blurRadius: 15,
        spreadRadius: 2,
        offset: const Offset(0, 5),
      ),
    ],
    border: Border.all(
      color: primaryLavender.withOpacity(0.3),
      width: 1,
    ),
  );

  static BoxDecoration get envelopeDecoration => BoxDecoration(
    gradient: primaryGradient,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: blushPink.withOpacity(0.3),
        blurRadius: 12,
        spreadRadius: 1,
        offset: const Offset(0, 4),
      ),
    ],
  );

  static BoxDecoration get lockedEnvelopeDecoration => BoxDecoration(
    color: Colors.grey.shade200,
    borderRadius: BorderRadius.circular(16),
    boxShadow: [
      BoxShadow(
        color: Colors.grey.withOpacity(0.2),
        blurRadius: 8,
        spreadRadius: 1,
        offset: const Offset(0, 2),
      ),
    ],
    border: Border.all(
      color: Colors.grey.shade300,
      width: 1,
    ),
  );

  // Animation Durations
  static const Duration fastAnimation = Duration(milliseconds: 300);
  static const Duration mediumAnimation = Duration(milliseconds: 500);
  static const Duration slowAnimation = Duration(milliseconds: 800);
  static const Duration extraSlowAnimation = Duration(milliseconds: 1200);

  // Custom Text Styles with Google Fonts
  static TextStyle get romanticTitle => GoogleFonts.merriweather(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: darkText,
    letterSpacing: 0.5,
    height: 1.2,
  );

  static TextStyle get invitationMessage => GoogleFonts.merriweather(
    fontSize: 16,
    color: darkText,
    height: 1.6,
    letterSpacing: 0.2,
  );

  static TextStyle get dateTimeStyle => GoogleFonts.merriweather(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: deepPurple,
    letterSpacing: 0.3,
  );

  static TextStyle get locationStyle => GoogleFonts.merriweather(
    fontSize: 16,
    fontWeight: FontWeight.w500,
    color: lightText,
    fontStyle: FontStyle.italic,
  );

  static TextStyle get statusStyle => GoogleFonts.merriweather(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
  );

  static TextStyle get countdownStyle => GoogleFonts.merriweather(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    color: softGold,
    letterSpacing: 1.0,
  );

  // Helper methods for dynamic colors
  static Color getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'accepted':
        return Colors.green.shade400;
      case 'rejected':
        return Colors.red.shade300;
      case 'pending':
        return deepPurple;
      case 'locked':
        return Colors.grey.shade500;
      case 'completed':
        return Colors.blue.shade400;
      default:
        return lightText;
    }
  }

  // Custom Shadows
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.08),
      blurRadius: 10,
      spreadRadius: 1,
      offset: const Offset(0, 3),
    ),
  ];

  static List<BoxShadow> get mediumShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.12),
      blurRadius: 15,
      spreadRadius: 2,
      offset: const Offset(0, 5),
    ),
  ];

  static List<BoxShadow> get strongShadow => [
    BoxShadow(
      color: Colors.black.withOpacity(0.16),
      blurRadius: 20,
      spreadRadius: 3,
      offset: const Offset(0, 8),
    ),
  ];

  // Custom Border Radius
  static const BorderRadius softRadius = BorderRadius.all(Radius.circular(12));
  static const BorderRadius mediumRadius = BorderRadius.all(Radius.circular(16));
  static const BorderRadius largeRadius = BorderRadius.all(Radius.circular(24));
  static const BorderRadius extraLargeRadius = BorderRadius.all(Radius.circular(32));
}