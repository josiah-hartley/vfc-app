import 'package:flutter/material.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';

class DownloadBeforePlayingDialog extends StatelessWidget {
  const DownloadBeforePlayingDialog({Key key, this.onDownload}) : super(key: key);
  final Function onDownload;

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      contentPadding: EdgeInsets.only(top: 14.0, bottom: 24.0, left: 20.0, right: 20.0),
      title: Text('Only downloaded messages can be played',
        style: Theme.of(context).primaryTextTheme.headline2.copyWith(fontSize: 18.0),
        textAlign: TextAlign.center,
      ),
      children: [
        Container(
          //padding: EdgeInsets.only(bottom: 20.0),
          child: ActionButton(
            text: 'Download',
            onPressed: () {
              onDownload();
              Navigator.of(context).pop();
            },
          ),
        ),
      ],
    );
  }
}