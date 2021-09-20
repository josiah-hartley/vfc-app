import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:voices_for_christ/ui/shared_theme.dart';

//Color unselectedColor = Colors.grey[400];
Color unselectedColor = Colors.white.withOpacity(0.8);
Color selectedColor = Colors.white;

ThemeData darkTheme = sharedTheme.copyWith(
  brightness: Brightness.dark,
  primaryColor: Color(0xff002D47),
  accentColor: Colors.white,
  highlightColor: Color(0xfffa7a0a),
  backgroundColor: Color(0xff002D47),
  cardColor: Color(0xff01466e),
  dialogBackgroundColor: Color(0xff002133),
  scaffoldBackgroundColor: darkBlue.withOpacity(0.75),
  bottomAppBarColor: Color(0xff002133),
  //bottomAppBarColor: Colors.black,
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
      headline1: GoogleFonts.montserrat(
        color: Colors.white,
      )
    ),
  ),
  bottomNavigationBarTheme: BottomNavigationBarThemeData(
    //backgroundColor: Color(0xff000d14),
    backgroundColor: Colors.black,
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
        color: Colors.white,
        width: 1.0,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderSide: BorderSide(
        color: Colors.white,
        width: 1.0,
      ),
    ),
    hintStyle: TextStyle(
      color: Colors.white.withOpacity(0.6),
      fontSize: 18.0,
    ),
  ),
);