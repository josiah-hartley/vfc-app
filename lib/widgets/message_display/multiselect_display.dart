import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/add_to_playlist_dialog.dart';
import 'package:voices_for_christ/widgets/dialogs/confirm_delete_dialog.dart';

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
          padding: EdgeInsets.only(right: 12.0),
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor.withOpacity(0.2),
          ),
          child: Row(
            children: [
              GestureDetector(
                onTap: onDeselectAll,
                child: Container(
                  color: Theme.of(context).accentColor.withOpacity(0.01),
                  padding: EdgeInsets.only(left: 24.0, right: 26.0, top: 17.0, bottom: 18.0),
                  child: Icon(CupertinoIcons.xmark, color: Theme.of(context).accentColor),
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.only(right: 14.0, top: 5.0, bottom: 6.0),
                  child: Text(_text,
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                      fontSize: 18.0,
                    )
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.only(top: 5.0, bottom: 6.0),
                child: GestureDetector(
                  onTap: () {
                    showDialog(
                      context: context, 
                      builder: (context) => popupMenu(context, model),
                      barrierColor: Colors.black.withOpacity(0.2),
                    );
                  },
                  child: Container(
                    color: Theme.of(context).primaryColor.withOpacity(0.01),
                    child: Icon(CupertinoIcons.ellipsis_vertical,
                      color: Theme.of(context).accentColor,
                      size: 24.0,
                    ),
                    padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget popupMenu(BuildContext context, MainModel model) {
    const TOP_POSITION = 115.0;
    const RIGHT_POSITION = 16.0;

    return SizedBox.expand(
      child: Stack(
        children: [
          GestureDetector(
            onTap: Navigator.of(context).pop,
            child: Container(color: Theme.of(context).backgroundColor.withOpacity(0.01)),
          ),
          Positioned(
            top: TOP_POSITION,
            right: RIGHT_POSITION,
            child: Container(
              decoration: BoxDecoration(
                color: Theme.of(context).dialogBackgroundColor,
                border: Border.all(
                  color: Theme.of(context).accentColor.withOpacity(0.5),
                  width: 1.0,
                ),
              ),
              child: _popupMenuActions(
                context: context,
                messages: selectedMessages.toList(),
                addAllToQueue: model.addMultipleMessagesToQueue,
                setMultiplePlayed: model.setMultiplePlayed,
                setMultipleFavorites: model.setMultipleFavorites,
                downloadAll: model.queueDownloads,
                deleteAllDownloads: model.deleteMessages,
              ),
            ),
          )
        ],
      ),
    );
  }

  Widget _popupMenuActions({
  BuildContext context,
  List<Message> messages,
  Function addAllToQueue,
  Function setMultiplePlayed,
  Function setMultipleFavorites,
  Function downloadAll,
  Function deleteAllDownloads}) {

    double height = MediaQuery.of(context).size.height * 2 / 3;
    double width = MediaQuery.of(context).size.width * 2 / 3;

    bool active = false;
    if (messages != null && messages.length > 0) {
      active = true;
    }

    List<Widget> _listChildren = [];
    if (showDownloadOptions == true) {
      _listChildren.add(_popupListAction(
        context: context,
        onPressed: () {
          downloadAll(selectedMessages.toList(), showPopup: true);
        },
        active: active,
        icon: Icons.download_sharp,
        text: 'Download',
      ));
      _listChildren.add(_popupListAction(
        context: context,
        onPressed: () {
          showDialog(
            context: context, 
            builder: (context) => ConfirmDeleteDialog(
              onConfirm: () {
                deleteAllDownloads(selectedMessages.toList());
                onDeselectAll();
              },
            ),
          );
        },
        popNavigator: false,
        active: active,
        icon: CupertinoIcons.delete,
        text: 'Remove downloads',
      ));
    }
    if (showQueueOptions == true) {
      _listChildren.add(_popupListAction(
        context: context,
        onPressed: () {
          List<Message> _downloadedMessages = messages.where((m) => m.isdownloaded == 1).toList();
          if (_downloadedMessages.length > 0) {
            String _m = _downloadedMessages.length > 1 ? 'messages' : 'message';
            addAllToQueue(_downloadedMessages);
            showToast('Added ${_downloadedMessages.length} $_m to queue');
          } else {
            showToast('None of the selected messages are downloaded');
          }
        },
        active: active,
        icon: CupertinoIcons.list_dash,
        text: 'Add to queue (only if downloaded)',
      ));
    }
    _listChildren.addAll([
      _popupListAction(
        context: context,
        onPressed: () {
          showDialog(
            context: context,
            builder: (context) => AddToPlaylistDialog(
              messageList: selectedMessages.toList(),
            ),
          );
        },
        popNavigator: false,
        active: active,
        icon: Icons.playlist_add,
        text: 'Add to playlist',
      ),
      _popupListAction(
        context: context,
        onPressed: () async {
          String _m = messages.length > 1 ? 'messages' : 'message';
          await setMultipleFavorites(messages, 1);
          showToast('Added ${messages.length} $_m to favorites');
        },
        active: active,
        icon: CupertinoIcons.star_fill,
        text: 'Add to favorites',
      ),
      _popupListAction(
        context: context,
        onPressed: () async {
          String _m = messages.length > 1 ? 'messages' : 'message';
          await setMultipleFavorites(messages, 0);
          showToast('Removed ${messages.length} $_m from favorites');
        },
        active: active,
        icon: CupertinoIcons.star_slash,
        text: 'Remove from favorites',
      ),
      _popupListAction(
        context: context,
        onPressed: () async {
          String _m = messages.length > 1 ? 'messages' : 'message';
          await setMultiplePlayed(messages, 1);
          showToast('Marked ${messages.length} $_m as played');
        },
        active: active,
        icon: CupertinoIcons.check_mark_circled,
        text: 'Mark as played',
      ),
      _popupListAction(
        context: context,
        onPressed: () async {
          String _m = messages.length > 1 ? 'messages' : 'message';
          await setMultiplePlayed(messages, 0);
          showToast('Marked ${messages.length} $_m as unplayed');
        },
        active: active,
        icon: CupertinoIcons.circle,
        text: 'Mark as unplayed',
      ),
    ]);

    return Container(
      color: Theme.of(context).backgroundColor.withOpacity(0.01),
      constraints: BoxConstraints(
        maxHeight: height,
        maxWidth: width,
      ),
      padding: EdgeInsets.symmetric(vertical: 5.0),
      child: ListView(
        shrinkWrap: true,
        children: _listChildren,
      ),
    );
  }

  Widget _popupListAction({BuildContext context, bool active, Function onPressed, IconData icon, String text, bool popNavigator = true}) {
    return GestureDetector(
      onTap: active 
        ? () { 
          onPressed();
          if (popNavigator) {
            Navigator.of(context).pop();
          }
        }
        : null,
      child: Container(
        color: Theme.of(context).backgroundColor.withOpacity(0.01),
        padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 4.0),
        child: Row(
          children: [
            Container(
              child: Icon(icon,
                color: active ? Theme.of(context).accentColor : Theme.of(context).accentColor.withOpacity(0.6),
                size: 20.0,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 14.0),
              child: Text(text,
                style: TextStyle(
                  color: active ? Theme.of(context).accentColor : Theme.of(context).accentColor.withOpacity(0.6),
                  fontSize: 16.0,
                )
              )
            ),
          ],
        )
      ),
    );
  }
}