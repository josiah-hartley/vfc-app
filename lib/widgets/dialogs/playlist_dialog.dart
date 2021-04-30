import 'dart:ui';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';
import 'package:voices_for_christ/widgets/dialogs/edit_playlist_title_dialog.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';

class PlaylistDialog extends StatefulWidget {
  PlaylistDialog({Key key, this.playlist}) : super(key: key);
  final Playlist playlist;

  @override
  _PlaylistDialogState createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  bool _reordering = false;

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
              child: _reordering
                ? Theme(
                  data: ThemeData(canvasColor: Colors.transparent),
                  child: ReorderableListView(
                    onReorder: (oldIndex, newIndex) {
                      model.reorderPlaylist(oldIndex: oldIndex - 1, newIndex: newIndex - 1);
                    },
                    shrinkWrap: true,
                    children: _reorderingAndDeletingChildren(model),
                  )
                )
                : ListView(
                  shrinkWrap: true,
                  children: _children(model),
                ),
            ),
          ),
        );
      }
    );
  }

  List<Widget> _children(MainModel model) {
    List<Widget> result = [
      Container(
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
                child: Text(model.selectedPlaylist?.title ?? 'Playlist',
                  style: Theme.of(context).primaryTextTheme.headline1.copyWith(
                    fontSize: 20.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            _playlistActionsButton(
              onDelete: model.deletePlaylist,
            ),
          ],
        ),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(
            color: Theme.of(context).accentColor
          ))
        ),
      )
    ];

    if (model.selectedPlaylist != null && model.selectedPlaylist.messages != null) {
      model.selectedPlaylist.messages.forEach((msg) {
        result.add(MessageCard(
          message: msg,
          playlist: model.selectedPlaylist,
        ));
      });
    }

    return result;
  }

  List<Widget> _reorderingAndDeletingChildren(MainModel model) {
    List<Widget> result = [
      Container(
        key: Key('0'),
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
                child: Text(model.selectedPlaylist?.title ?? 'Playlist',
                  style: Theme.of(context).primaryTextTheme.headline1.copyWith(
                    fontSize: 20.0,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                model.saveReorderingChanges();
                setState(() {
                  _reordering = false;
                });
              },
              child: Container(
                padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
                color: Theme.of(context).backgroundColor.withOpacity(0.01),
                child: Icon(CupertinoIcons.check_mark,
                  color: Theme.of(context).accentColor,
                  size: 24.0,
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
      )
    ];

    if (model.selectedPlaylist != null && model.selectedPlaylist.messages != null) {
      for (int i = 0; i < model.selectedPlaylist.messages.length; i++) {
        Message msg = model.selectedPlaylist.messages[i];
        /*result.add(MessageCard(
          message: msg,
          playlist: model.selectedPlaylist,
        ));*/
        result.add(
          Container(
            key: Key('${msg.id}'),
            padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
            child: Column(
              children: [
                Row(
                  children: [
                    /*initialSticker(
                      context: context,
                      name: message.speaker, 
                      borderColor: Theme.of(context).accentColor,
                      selected: selected,
                      onSelect: onSelect,
                    ),*/
                    ReorderableDragStartListener(
                      index: i,
                      child: Container(
                        padding: EdgeInsets.only(left: 10.0),
                        child: Container(
                          child: Icon(CupertinoIcons.line_horizontal_3, 
                            color: Theme.of(context).accentColor
                          ),
                          height: 40.0,
                          width: 40.0,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Theme.of(context).highlightColor.withOpacity(0.01),
                            shape: BoxShape.rectangle,
                            /*border: Border.all(
                              color: Theme.of(context).accentColor,
                              width: 1.0,
                            )*/
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: messageTitleAndSpeakerDisplay(
                        message: msg,
                        truncateTitle: true,
                        textColor: Theme.of(context).accentColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    }

    return result;
  }

  void editTitle() async {
    String newTitle = await showDialog(
      context: context, 
      builder: (context) => EditPlaylistTitleDialog(
        playlist: widget.playlist,
        originalTitle: widget.playlist?.title,
      ),
    );
    if (newTitle != null) {
      setState(() {
        widget.playlist.title = newTitle;
      });
    }
  }

  void deletePlaylist(Function onDelete) async {
    bool delete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${widget.playlist.title}?',
          style: TextStyle(color: Theme.of(context).accentColor),
        ),
        content: Container(
          child: Text('This cannot be undone.',
            style: TextStyle(color: Theme.of(context).accentColor),
          ),
        ),
        actions: [
          ActionButton(
            text: 'Delete',
            onPressed: () {
              Navigator.of(context).pop(true);
            },
          ),
          ActionButton(
            text: 'Cancel',
            onPressed: () { Navigator.of(context).pop(false); },
          ),
        ],
      ),
    );
    if (delete) {
      onDelete(widget.playlist);
      Navigator.of(context).pop();
    }
  }

  void openReorderingList() {
    setState(() {
      _reordering = true;
    });
  }

  void downloadAll() {

  }

  void deleteAllDownloads() {

  }

  void addAllToQueue() {

  }

  void addAllToFavorites() {

  }

  void removeAllFromFavorites() {

  }

  Widget _playlistActionsButton({Function onDelete}) {
    bool active = false;
    if (widget.playlist != null && widget.playlist.messages != null && widget.playlist.messages.length > 0) {
      active = true;
    }
    return Material(
      color: Theme.of(context).backgroundColor.withOpacity(0.01),
      child: PopupMenuButton<int>(
        //iconSize: 25.0,
        icon: Icon(CupertinoIcons.ellipsis_vertical,
          color: Theme.of(context).accentColor,
          size: 24.0,
        ),
        color: Theme.of(context).primaryColor,
        shape: Border.all(color: Theme.of(context).accentColor.withOpacity(0.2)),
        offset: Offset(0.0, 30.0),
        elevation: 1.0,
        itemBuilder: (context) {
          return [
            _playlistAction(
              value: 0,
              active: true,
              icon: CupertinoIcons.pencil,
              text: 'Edit title',
            ),
            _playlistAction(
              value: 1,
              active: true,
              icon: CupertinoIcons.xmark,
              text: 'Delete playlist',
            ),
            _playlistAction(
              value: 2,
              active: active,
              icon: CupertinoIcons.line_horizontal_3,
              text: 'Reorder',
            ),
            _playlistAction(
              value: 3,
              active: active,
              icon: Icons.download_sharp,
              text: 'Download all',
            ),
            _playlistAction(
              value: 4,
              active: active,
              icon: CupertinoIcons.delete,
              text: 'Delete all downloads',
            ),
            _playlistAction(
              value: 5,
              active: active,
              icon: CupertinoIcons.list_dash,
              text: 'Add to queue',
            ),
            _playlistAction(
              value: 6,
              active: active,
              icon: CupertinoIcons.star_fill,
              text: 'Add all to favorites',
            ),
            _playlistAction(
              value: 7,
              active: active,
              icon: CupertinoIcons.star_slash,
              text: 'Remove all from favorites',
            ),
          ];
        },
        onSelected: (value) {
          switch (value) {
            case 0:
              editTitle();
              break;
            case 1:
              deletePlaylist(onDelete);
              break;
            case 2:
              openReorderingList();
              break;
            case 3:
              downloadAll();
              break;
            case 4:
              deleteAllDownloads();
              break;
            case 5:
              addAllToQueue();
              break;
            case 6:
              addAllToFavorites();
              break;
            case 7:
              removeAllFromFavorites();
              break;
          }
        },
      ),
    );
    /*return GestureDetector(
      onTap: () {
        setState(() {
          _reordering = true;
        });
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 8.0),
        color: Theme.of(context).backgroundColor.withOpacity(0.01),
        child: Icon(CupertinoIcons.ellipsis_vertical,
          color: Theme.of(context).accentColor,
          size: 30.0,
        ),
      ),
    );*/
  }

  PopupMenuItem<int> _playlistAction({bool active, int value, IconData icon, String text}) {
    return PopupMenuItem<int>(
      value: value,
      enabled: active,
      child: Container(
        child: Row(
          children: [
            Container(
              child: Icon(icon,
                color: active ? Theme.of(context).accentColor : Theme.of(context).accentColor.withOpacity(0.6),
                size: 30.0,
              ),
            ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 14.0),
              child: Text(text,
                style: TextStyle(
                  color: active ? Theme.of(context).accentColor : Theme.of(context).accentColor.withOpacity(0.6),
                  fontSize: 20.0,
                )
              )
            ),
          ],
        )
      ),
    );
  }
}