import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

Color unselectedColor = Colors.grey[500];
Color selectedColor = Colors.white;

ThemeData darkTheme = sharedTheme.copyWith(
  brightness: Brightness.dark,
  primaryColor: Colors.blue[800],
  accentColor: Colors.white,
  backgroundColor: Color(0xff002D47),
  dialogBackgroundColor: Color(0xff002D47).withOpacity(0.9),
  bottomAppBarColor: Color(0xff002133),
  appBarTheme: AppBarTheme(
    color: Colors.transparent,
    elevation: 0.0,
    iconTheme: IconThemeData(
      color: Colors.white,
    ),
    textTheme: TextTheme(
      headline1: GoogleFonts.montserrat()
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    backgroundColor: Color(0xff000d14),
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