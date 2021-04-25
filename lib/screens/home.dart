import 'package:flutter/material.dart';

class HomePage extends StatelessWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    print('building home');
    return Container(
      child: Container(
        alignment: Alignment.topCenter,
        child: Text('Home page')
      ),
    );
  }
}