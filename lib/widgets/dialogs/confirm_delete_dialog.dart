import 'package:flutter/material.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';

class ConfirmDeleteDialog extends StatelessWidget {
  const ConfirmDeleteDialog({Key key, this.messageTitle, this.onConfirm}) : super(key: key);
  final String messageTitle;
  final Function onConfirm;

  @override
  Widget build(BuildContext context) {
    String body = messageTitle == null 
      ? 'Are you sure you want to delete the downloads for these messages?'
      : 'Are you sure you want to delete the download for $messageTitle?';
    return SimpleDialog(
      contentPadding: EdgeInsets.only(top: 14.0, bottom: 24.0, left: 20.0, right: 20.0),
      title: Text('Delete?',
        style: Theme.of(context).primaryTextTheme.headline2.copyWith(fontSize: 18.0),
        textAlign: TextAlign.center,
      ),
      children: [
        Container(
          padding: EdgeInsets.only(bottom: 14.0),
          child: Text(body,
            style: Theme.of(context).primaryTextTheme.headline4,
          ),
        ),
        Container(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                child: ActionButton(
                  text: 'Yes, Delete',
                  onPressed: () {
                    onConfirm();
                    Navigator.of(context).pop();
                  },
                )
              ),
              Container(
                child: ActionButton(
                  text: 'Cancel',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                )
              ),
            ],
          ),
        ),
      ],
    );
  }
}