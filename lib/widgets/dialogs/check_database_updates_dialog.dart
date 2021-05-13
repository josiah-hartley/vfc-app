import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;

class CheckDatabaseUpdatesDialog extends StatefulWidget {
  CheckDatabaseUpdatesDialog({Key key, this.lastUpdated}) : super(key: key);
  final DateTime lastUpdated;

  @override
  _CheckDatabaseUpdatesDialogState createState() => _CheckDatabaseUpdatesDialogState();
}

class _CheckDatabaseUpdatesDialogState extends State<CheckDatabaseUpdatesDialog> {
  Duration difference = Duration(days: 0);

  @override
  void initState() { 
    super.initState();
    setState(() {
      difference = DateTime.now().difference(widget.lastUpdated);
    });
  }

  @override
  Widget build(BuildContext context) {
    int staleDays = Constants.DAYS_TO_MANUALLY_CHECK_CLOUD;

    return SimpleDialog(
      title: Text('Check for New Messages',
        style: TextStyle(
          color: Theme.of(context).accentColor,
        ),
      ),
      children: [
        Container(
          alignment: Alignment.center,
          child: Text('Last updated on ${widget.lastUpdated?.month}/${widget.lastUpdated?.day}/${widget.lastUpdated?.year}',
            style: TextStyle(
              color: Theme.of(context).accentColor,
            ),
          ),
        ),
        Container(
          padding: EdgeInsets.symmetric(vertical: 14.0, horizontal: 20.0),
          child: TextButton(
            onPressed: difference.inDays > staleDays
              ? () { print('update'); }
              : null,
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
              color: difference.inDays > staleDays
                      ? Theme.of(context).accentColor
                      : Theme.of(context).accentColor.withOpacity(0.1),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(CupertinoIcons.refresh,
                    size: 16.0,
                    color: difference.inDays > staleDays
                      ? Theme.of(context).primaryColor
                      : Theme.of(context).accentColor.withOpacity(0.6),
                  ),
                  Container(
                    padding: EdgeInsets.only(left: 5.0, top: 2.0),
                    child: Text('Update',
                      style: TextStyle(
                        color: difference.inDays > staleDays
                          ? Theme.of(context).primaryColor
                          : Theme.of(context).accentColor.withOpacity(0.6),
                        fontSize: 18.0,  
                      ),
                    )
                  ),
                ],
              )
            ),
          ),
        ),
      ],
    );
  }
}