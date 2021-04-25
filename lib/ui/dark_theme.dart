import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

Color unselectedColor = Colors.grey[400];
Color selectedColor = Colors.white;

ThemeData darkTheme = sharedTheme.copyWith(
  brightness: Brightness.dark,
  primaryColor: Color(0xff002D47),
  accentColor: Colors.white,
  backgroundColor: Color(0xff002D47),
  dialogBackgroundColor: Color(0xff002133),
  bottomAppBarColor: Color(0xff002133),
  //bottomAppBarColor: Color(0xff013857),
  primaryTextTheme: TextTheme(
    headline1: TextStyle(
      color: Colors.white,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
    ),
    headline2: TextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.w400,
    ),
    headline3: TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.w700,
    ),
    headline4: TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
    ),
  ),
  accentTextTheme: TextTheme(
    headline1: TextStyle(
      color: Colors.white,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
    ),
    headline2: TextStyle(
      color: Colors.white,
      fontSize: 20.0,
      fontWeight: FontWeight.w400,
    ),
    headline3: TextStyle(
      color: Colors.white,
      fontSize: 16.0,
      fontWeight: FontWeight.w700,
    ),
    headline4: TextStyle(
      color: Colors.white,
      fontSize: 14.0,
      fontWeight: FontWeight.w400,
    ),
  ),
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