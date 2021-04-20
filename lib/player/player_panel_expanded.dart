import 'package:flutter/material.dart';

class PlayerPanelExpanded extends StatefulWidget {
  PlayerPanelExpanded({Key key}) : super(key: key);

  @override
  _PlayerPanelExpandedState createState() => _PlayerPanelExpandedState();
}

class _PlayerPanelExpandedState extends State<PlayerPanelExpanded> {
  @override
  Widget build(BuildContext context) {
    return Container(
      alignment: Alignment.bottomCenter,
      color: Theme.of(context).bottomAppBarColor,
      child: Text('Panel'),
    );
  }
}