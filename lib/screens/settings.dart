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
          padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
          child: ListView(
            padding: EdgeInsets.only(top: 0.0),
            children: [
              _darkModeToggle(
                context: context,
                value: model.darkMode, 
                toggle: model.toggleDarkMode
              ),
              _storageUsage(
                context: context, 
                bytes: model.downloadedBytes
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _darkModeToggle({BuildContext context, bool value, Function toggle}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text('Dark Theme',
              style: Theme.of(context).primaryTextTheme.headline2,
            )
          ),
          Container(
            child: Switch(
              value: value,
              onChanged: (val) { toggle(); },
              activeColor: Theme.of(context).accentColor,
              inactiveThumbColor: Theme.of(context).accentColor.withOpacity(0.8),
              inactiveTrackColor: Theme.of(context).accentColor.withOpacity(0.25),
            ),
          ),
        ],
      )
    );
  }

  Widget _storageUsage({BuildContext context, int bytes}) {
    double mb = bytes / 1000000;
    double gb = mb / 1000;
    // round megabytes to 1 decimal place
    mb = (mb * 10).round() / 10;
    // round gigabytes to 2 decimal places
    gb = (gb * 100).round() / 100;
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Storage Used',
                  style: Theme.of(context).primaryTextTheme.headline2,
                ),
                Container(
                  padding: EdgeInsets.only(top: 5.0, right: 25.0),
                  child: Text('You can remove downloaded messages to free up space',
                    style: Theme.of(context).primaryTextTheme.headline4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            child: Text(mb > 500 ? '$gb GB' : '$mb MB',
              style: Theme.of(context).primaryTextTheme.headline2,
            ),
          ),
        ],
      ),
    );
  }
}