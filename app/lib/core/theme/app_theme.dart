import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: kBgBase,
        colorScheme: const ColorScheme.dark(
          surface: kSurface1,
          primary: kAccentMain,
          onPrimary: Colors.black,
          onSurface: kTextPrimary,
          error: Color(0xFFFF6B6B),
          onError: Colors.white,
        ),
        cardTheme: CardTheme(
          color: kSurface2,
          elevation: 0,
          margin: EdgeInsets.zero,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
            side: const BorderSide(color: kBorderDefault),
          ),
        ),
        appBarTheme: AppBarTheme(
          backgroundColor: kBgBase,
          foregroundColor: kTextPrimary,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: GoogleFonts.notoSerifJp(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            color: kTextPrimary,
          ),
        ),
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: kAccentMain,
          foregroundColor: Colors.black,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: kSurface3,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorderDefault),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kBorderDefault),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: kAccentMain),
          ),
          labelStyle: const TextStyle(color: kTextSub),
          hintStyle: const TextStyle(color: kTextMuted),
        ),
        chipTheme: const ChipThemeData(
          backgroundColor: kAccentSoft,
          labelStyle: TextStyle(
            color: kAccentMain,
            fontSize: 10,
            fontWeight: FontWeight.w600,
          ),
          padding: EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          side: BorderSide(color: kAccentGlow),
          shape: StadiumBorder(),
        ),
        progressIndicatorTheme: const ProgressIndicatorThemeData(
          color: kAccentMain,
        ),
        dividerTheme: const DividerThemeData(color: kBorderDefault),
        textTheme: const TextTheme(
          bodyLarge: TextStyle(color: kTextPrimary, fontSize: 14),
          bodyMedium: TextStyle(color: kTextPrimary, fontSize: 13),
          bodySmall: TextStyle(color: kTextSub, fontSize: 11),
        ),
        useMaterial3: true,
      );
}
