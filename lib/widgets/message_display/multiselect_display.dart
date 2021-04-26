import 'dart:collection';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/data_models/message_class.dart';

Widget multiselectDisplay({BuildContext context, 
  LinkedHashSet<Message> selectedMessages,
  Function onDeselectAll}) {
    String _text = '${selectedMessages.length} selected';
    if (selectedMessages.length == Constants.MESSAGE_SELECTION_LIMIT) {
      _text += ' (max allowed)';
    }
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor.withOpacity(0.2),
      ),
      child: Row(
        children: [
          IconButton(
            icon: Icon(CupertinoIcons.xmark, color: Theme.of(context).accentColor),
            onPressed: onDeselectAll,
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.0),
              child: Text(_text,
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 18.0,
                )
              ),
            ),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.ellipsis_vertical, color: Theme.of(context).accentColor), 
            onPressed: () {
              selectedMessages.forEach((element) {print(element.title);});
            },
          )
        ],
      ),
    );
}