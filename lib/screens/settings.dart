import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        return Container(
          child: ListView(
            children: [
              _darkModeToggle(model.toggleDarkMode),
            ],
          ),
        );
      }
    );
  }

  Widget _darkModeToggle(Function toggle) {
    return Container(
      child: TextButton(
        child: Text('Toggle Theme'),
        onPressed: toggle,
      )
    );
  }
}