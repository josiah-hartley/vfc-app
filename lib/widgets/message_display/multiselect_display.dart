import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/add_to_playlist_dialog.dart';

class MultiSelectDisplay extends StatelessWidget {
  const MultiSelectDisplay({Key key, this.selectedMessages, this.onDeselectAll, this.showDownloadOptions = true, this.showQueueOptions = true}) : super(key: key);
  final LinkedHashSet<Message> selectedMessages;
  final Function onDeselectAll;
  final bool showDownloadOptions;
  final bool showQueueOptions;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        String _text = '${selectedMessages.length} selected';
        if (selectedMessages.length == Constants.MESSAGE_SELECTION_LIMIT) {
          _text += ' (max allowed)';
        }
        return Container(
          padding: EdgeInsets.only(left: 12.0, right: 12.0, top: 5.0, bottom: 6.0),
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor.withOpacity(0.2),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onDeselectAll,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                  child: Icon(CupertinoIcons.xmark, color: Theme.of(context).accentColor),
                ),
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
              _listActionsButton(
                context: context,
                messages: selectedMessages.toList(),
                addAllToQueue: model.addMultipleMessagesToQueue,
                setMultipleFavorites: model.setMultipleFavorites,
                downloadAll: model.queueDownloads,
                deleteAllDownloads: model.deleteMessages,
              ),
              /*IconButton(
                icon: Icon(CupertinoIcons.ellipsis_vertical, color: Theme.of(context).accentColor), 
                onPressed: () {
                  List<Message> msgList = selectedMessages.toList();
                  selectedMessages.forEach((element) {print(element.title);});
                },
              )*/
            ],
          ),
        );
      }
    );
  }

  /*void downloadAll() {

  }*/

  Widget _listActionsButton({
    BuildContext context,
    List<Message> messages,
    Function addAllToQueue,
    Function setMultipleFavorites,
    Function downloadAll,
    Function deleteAllDownloads}) {
    bool active = false;
    if (messages != null && messages.length > 0) {
      active = true;
    }

    List<PopupMenuItem<int>> _listChildren = [];
    if (showDownloadOptions == true) {
      _listChildren.add(_listAction(
        context: context,
        value: 0,
        active: active,
        icon: Icons.download_sharp,
        text: 'Download all',
      ));
      _listChildren.add(_listAction(
        context: context,
        value: 1,
        active: active,
        icon: CupertinoIcons.delete,
        text: 'Remove downloads',
      ));
    }
    if (showQueueOptions == true) {
      _listChildren.add(_listAction(
        context: context,
        value: 2,
        active: active,
        icon: CupertinoIcons.list_dash,
        text: 'Add to queue (downloaded only)',
      ));
    }
    _listChildren.addAll([
      _listAction(
        context: context,
        value: 3,
        active: active,
        icon: Icons.playlist_add,
        text: 'Add to playlist',
      ),
      _listAction(
        context: context,
        value: 4,
        active: active,
        icon: CupertinoIcons.star_fill,
        text: 'Add to favorites',
      ),
      _listAction(
        context: context,
        value: 5,
        active: active,
        icon: CupertinoIcons.star_slash,
        text: 'Remove from favorites',
      ),
    ]);

    return Material(
      color: Theme.of(context).backgroundColor.withOpacity(0.01),
      child: PopupMenuButton<int>(
        //iconSize: 25.0,
        icon: Icon(CupertinoIcons.ellipsis_vertical,
          color: Theme.of(context).accentColor,
          size: 24.0,
        ),
        color: Theme.of(context).primaryColor,
        shape: Border.all(color: Theme.of(context).accentColor.withOpacity(0.4)),
        //offset: Offset(0.0, 100.0),
        elevation: 20.0,
        itemBuilder: (context) {
          return _listChildren;
        },
        onSelected: (value) async {
          switch (value) {
            case 0:
              downloadAll(selectedMessages.toList());
              break;
            case 1:
              deleteAllDownloads(selectedMessages.toList());
              onDeselectAll();
              break;
            case 2:
              List<Message> _downloadedMessages = messages.where((m) => m.isdownloaded == 1).toList();
              if (_downloadedMessages.length > 0) {
                String _m = _downloadedMessages.length > 1 ? 'messages' : 'message';
                addAllToQueue(_downloadedMessages);
                showToast('Added ${_downloadedMessages.length} $_m to queue');
              } else {
                showToast('None of the selected messages are downloaded');
              }
              break;
            case 3:
              showDialog(
                context: context,
                builder: (context) => AddToPlaylistDialog(
                  messageList: selectedMessages.toList(),
                ),
              );
              break;
            case 4:
              String _m = messages.length > 1 ? 'messages' : 'message';
              await setMultipleFavorites(messages, 1);
              showToast('Added ${messages.length} $_m to favorites');
              break;
            case 5:
              String _m = messages.length > 1 ? 'messages' : 'message';
              await setMultipleFavorites(messages, 0);
              showToast('Removed ${messages.length} $_m from favorites');
              break;
          }
        },
      ),
    );
  }

  PopupMenuItem<int> _listAction({BuildContext context, bool active, int value, IconData icon, String text}) {
    return PopupMenuItem<int>(
      value: value,
      enabled: active,
      child: Container(
        child: Row(
          children: [
            Container(
              child: Icon(icon,
                color: active ? Theme.of(context).accentColor : Theme.of(context).accentColor.withOpacity(0.6),
                size: 22.0,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
              child: Text(text,
                style: TextStyle(
                  color: active ? Theme.of(context).accentColor : Theme.of(context).accentColor.withOpacity(0.6),
                  fontSize: 18.0,
                )
              )
            ),
          ],
        )
      ),
    );
  }
}