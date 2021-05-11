import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

Color unselectedColor = darkBlue.withOpacity(0.75);
Color selectedColor = darkBlue;

ThemeData lightTheme = sharedTheme.copyWith(
  brightness: Brightness.light,
  primaryColor: Colors.white,
  accentColor: darkBlue,
  highlightColor: Color(0xfffa7a0a),
  backgroundColor: Color(0xffe5f6ff).withOpacity(0.5),
  cardColor: Color(0xffc5e1f0),
  dialogBackgroundColor: Colors.white, //Color(0xffc5dfed),
  //bottomAppBarColor: Color(0xff002133),
  bottomAppBarColor: Color(0xff013857),
  primaryTextTheme: TextTheme(
    headline1: TextStyle(
      color: darkBlue,
      fontSize: 24.0,
      fontWeight: FontWeight.w700,
    ),
    headline2: TextStyle(
      color: darkBlue,
      fontSize: 20.0,
      fontWeight: FontWeight.w400,
    ),
    headline3: TextStyle(
      color: darkBlue,
      fontSize: 16.0,
      fontWeight: FontWeight.w700,
    ),
    headline4: TextStyle(
      color: darkBlue,
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
  ),
  inputDecorationTheme: InputDecorationTheme(
    enabledBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: darkBlue,
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: darkBlue,
        width: 1.0,
      ),
    ),
    hintStyle: TextStyle(
      color: darkBlue.withOpacity(0.6),
      fontSize: 18.0,
    ),
  ),
);