import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTypography {
  AppTypography._();

  static TextTheme textTheme(Brightness brightness) {
    final base = brightness == Brightness.light
        ? Typography.blackMountainView
        : Typography.whiteMountainView;
    return GoogleFonts.beVietnamProTextTheme(base).copyWith(
      displayLarge: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w700),
      headlineMedium: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
      titleLarge: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
      bodyLarge: GoogleFonts.beVietnamPro(fontSize: 16, height: 1.5),
      bodyMedium: GoogleFonts.beVietnamPro(fontSize: 14, height: 1.5),
      labelLarge: GoogleFonts.beVietnamPro(fontWeight: FontWeight.w600),
    );
  }
}
