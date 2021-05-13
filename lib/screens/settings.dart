import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/check_database_updates_dialog.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        return SizedBox.expand(
          child: Material(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 12.0),
              color: Theme.of(context).backgroundColor,
              child: ListView(
                padding: EdgeInsets.only(top: 0.0),
                children: [
                  _title(context),
                  _darkModeToggle(
                    context: context,
                    value: model.darkMode, 
                    toggle: model.toggleDarkMode,
                  ),
                  _downloadOverDataToggle(
                    context: context,
                    value: model.downloadOverData, 
                    toggle: model.toggleDownloadOverData,
                  ),
                  _storageUsage(
                    context: context, 
                    bytes: model.downloadedBytes,
                  ),
                  _checkForUpdates(
                    context: context,
                    lastUpdated: model.cloudLastCheckedDate,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _title(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).accentColor.withOpacity(0.6),
            width: 1.0,
          )
        )
      ),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              color: Theme.of(context).backgroundColor.withOpacity(0.01),
              padding: EdgeInsets.only(right: 10.0, top: 12.0, bottom: 12.0),
              child: Icon(CupertinoIcons.back, 
                size: 34.0,
                color: Theme.of(context).accentColor
              ),
            ),
            onTap: () { Navigator.of(context).pop(); },
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(top: 2.0),
              child: Text('SETTINGS', 
                style: Theme.of(context).appBarTheme.textTheme.headline1.copyWith(fontSize: 22.0),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _darkModeToggle({BuildContext context, bool value, Function toggle}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Text('Dark theme',
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

  Widget _downloadOverDataToggle({BuildContext context, bool value, Function toggle}) {
    String text = value ? 'Messages will download over WiFi or mobile connections' : 'Messages will only download over WiFi';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Download over data',
                  style: Theme.of(context).primaryTextTheme.headline2,
                ),
                Container(
                  padding: EdgeInsets.only(top: 5.0, right: 25.0),
                  child: Text(text,
                    style: Theme.of(context).primaryTextTheme.headline4,
                  ),
                ),
              ],
            ),
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
                Text('Storage used',
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

  Widget _checkForUpdates({BuildContext context, int lastUpdated}) {
    DateTime d = DateTime.fromMillisecondsSinceEpoch(lastUpdated);
    String lastUpdatedReadable = '${d.month}/${d.day}/${d.year}';
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          builder: (context) => CheckDatabaseUpdatesDialog(lastUpdated: d),
        );
      },
      child: Container(
        color: Theme.of(context).backgroundColor.withOpacity(0.01),
        padding: EdgeInsets.symmetric(vertical: 12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Check for new messages',
              style: Theme.of(context).primaryTextTheme.headline2,
            ),
            Container(
              padding: EdgeInsets.only(top: 5.0, right: 25.0),
              child: Text('Last updated on $lastUpdatedReadable',
                style: Theme.of(context).primaryTextTheme.headline4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}