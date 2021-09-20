import 'package:flutter/material.dart';

class ActionButton extends StatelessWidget {
  const ActionButton({Key key, this.text, this.onPressed}) : super(key: key);
  final String text;
  final Function onPressed;

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: onPressed, 
      child: Container(
        decoration: BoxDecoration(
          color: Theme.of(context).accentColor,
          //borderRadius: BorderRadius.circular(25.0),
        ),
        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
        child: Text(text,
          style: TextStyle(
            color: Theme.of(context).primaryColor,
            fontSize: 16.0,
          )
        )
      ),
    );
  }
}