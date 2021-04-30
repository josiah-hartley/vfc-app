import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void showToast(String text) {
  Fluttertoast.showToast(
    msg: '$text',
    backgroundColor: Color(0xff002133),
    textColor: Colors.white,
    fontSize: 16.0,
  );
}