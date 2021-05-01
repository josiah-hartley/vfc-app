import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';

class QueueDialog extends StatefulWidget {
  QueueDialog({Key key}) : super(key: key);

  @override
  _QueueDialogState createState() => _QueueDialogState();
}

class _QueueDialogState extends State<QueueDialog> {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        return SizedBox.expand(
          child: BackdropFilter(
            filter: ImageFilter.blur(
              sigmaX: 10.0,
              sigmaY: 10.0,
            ),
            child: Container(
              color: Theme.of(context).backgroundColor.withOpacity(0.7),
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 16.0),
              child: Column(
                children: [
                  _titleAndActions(),
                  Expanded(
                    child: ListView(
                      shrinkWrap: true,
                      children: _children(model),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _titleAndActions() {
    return Container(
      padding: EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          GestureDetector(
            child: Container(
              padding: EdgeInsets.only(right: 12.0),
              child: Icon(CupertinoIcons.back, 
                size: 34.0,
                color: Theme.of(context).accentColor
              ),
            ),
            onTap: () { Navigator.of(context).pop(); },
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: 10.0),
              child: Text('Queue',
                style: Theme.of(context).primaryTextTheme.headline1.copyWith(
                  fontSize: 20.0,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ],
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Theme.of(context).accentColor
        ))
      ),
    );
  }

  List<Widget> _children(MainModel model) {
    List<Widget> result = [];

    Playlist _queueAsPlaylist = Playlist(-1, 0, 'Queue', model.queue);

    model.queue.forEach((queueItem) {
      result.add(MessageCard(
        message: queueItem,
        playlist: _queueAsPlaylist,
      ));
    });

    return result;
  }
}