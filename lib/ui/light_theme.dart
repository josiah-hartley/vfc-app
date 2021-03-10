import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

Color unselectedColor = Colors.grey[600];
Color selectedColor = darkBlue;

ThemeData lightTheme = sharedTheme.copyWith(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  accentColor: darkBlue,
  backgroundColor: Color(0xffe5f6ff).withOpacity(0.5),
  dialogBackgroundColor: Color(0xffe5f6ff).withOpacity(0.7),
  bottomAppBarColor: Color(0xff002133),
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    elevation: 0.0,
    iconTheme: IconThemeData(
      color: darkBlue,
    ),
    textTheme: TextTheme(
      headline1: GoogleFonts.montserrat(
        color: darkBlue,
      )
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    //backgroundColor: Color(0xff000d14),
    elevation: 0.0,
    selectedItemColor: selectedColor,
    unselectedItemColor: unselectedColor,
    selectedLabelStyle: TextStyle(
      fontWeight: FontWeight.bold,
      fontSize: 16.0,
    ),
    unselectedLabelStyle: TextStyle(
      fontWeight: FontWeight.w400,
      fontSize: 16.0,
    ),
    selectedIconTheme: IconThemeData(
      color: selectedColor,
    ),
    unselectedIconTheme: IconThemeData(
      color: unselectedColor,
    ),
  )
);