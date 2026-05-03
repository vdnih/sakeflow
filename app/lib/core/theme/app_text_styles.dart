import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTextStyles {
  static TextStyle headingLarge({Color? color}) => GoogleFonts.notoSerifJp(
        fontSize: 22,
        fontWeight: FontWeight.w700,
        color: color ?? kTextPrimary,
      );

  static TextStyle headingMedium({Color? color}) => GoogleFonts.notoSerifJp(
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: color ?? kTextPrimary,
      );

  static TextStyle headingSmall({Color? color}) => GoogleFonts.notoSerifJp(
        fontSize: 13,
        fontWeight: FontWeight.w600,
        color: color ?? kTextPrimary,
      );
}
