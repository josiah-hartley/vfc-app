import 'dart:collection';
import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';
import 'package:voices_for_christ/widgets/dialogs/edit_playlist_title_dialog.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';
import 'package:voices_for_christ/widgets/message_display/multiselect_display.dart';

class PlaylistDialog extends StatefulWidget {
  PlaylistDialog({Key key}) : super(key: key);

  @override
  _PlaylistDialogState createState() => _PlaylistDialogState();
}

class _PlaylistDialogState extends State<PlaylistDialog> {
  bool _reordering = false;
  LinkedHashSet<Message> _selectedMessages = LinkedHashSet();

  void _toggleMessageSelection(Message message) {
    setState(() {
      if (_selectedMessages.contains(message)) {
        _selectedMessages.remove(message);
      } else {
        if (_selectedMessages.length < Constants.MESSAGE_SELECTION_LIMIT) {
          _selectedMessages.add(message);
        }
      }
    });
  }

  void _selectAll(List<Message> messages) {
    if (messages.length > Constants.MESSAGE_SELECTION_LIMIT) {
      // max messages that can be selected
      messages = messages.sublist(0, Constants.MESSAGE_SELECTION_LIMIT - 1);
    }
    setState(() {
      _selectedMessages = LinkedHashSet.from(messages);
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedMessages = LinkedHashSet();
    });
  }

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
                  _selectedMessages.length > 0
                  ? MultiSelectDisplay(
                    selectedMessages: _selectedMessages,
                    onDeselectAll: _deselectAll,
                  )
                  : _titleAndActions(model, _reordering),
                  Expanded(
                    child: _reordering
                    ? Theme(
                      data: ThemeData(canvasColor: Colors.transparent),
                      child: ReorderableListView(
                        onReorder: (oldIndex, newIndex) {
                          model.reorderPlaylist(oldIndex: oldIndex, newIndex: newIndex);
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
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _titleAndActions(MainModel model, bool reordering) {
    List<Widget> _titleChildren = [
      GestureDetector(
        child: Container(
          padding: EdgeInsets.only(right: 12.0),
          child: Icon(CupertinoIcons.back, 
            size: 32.0,
            color: Theme.of(context).accentColor
          ),
        ),
        onTap: () { Navigator.of(context).pop(); },
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 10.0),
          child: Text(model.selectedPlaylist?.title ?? 'Playlist',
            overflow: reordering ? TextOverflow.ellipsis : TextOverflow.visible,
            style: Theme.of(context).primaryTextTheme.headline1.copyWith(
              fontSize: 20.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];

    if (reordering) {
      _titleChildren.add(TextButton(
        onPressed: () async {
          await model.saveReorderingChanges();
          setState(() {
            _reordering = false;
          });
        }, 
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(5.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Text('Save',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16.0,
            )
          )
        ),
      ));

      _titleChildren.add(TextButton(
        onPressed: () async {
          await model.loadMessagesOnCurrentPlaylist();
          setState(() {
            _reordering = false;
          });
        }, 
        child: Container(
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor,
            borderRadius: BorderRadius.circular(5.0),
          ),
          padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 12.0),
          child: Text('Cancel',
            style: TextStyle(
              color: Theme.of(context).primaryColor,
              fontSize: 16.0,
            )
          )
        ),
      ));
    } else {
      _titleChildren.add(_playlistActionsButton(
        playlist: model.selectedPlaylist,
        onDelete: model.deletePlaylist,
        addAllToQueue: model.addMultipleMessagesToQueue,
        setMultipleFavorites: model.setMultipleFavorites,
      ));
    }

    return Container(
      key: Key('0'),
      padding: EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: _titleChildren,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Theme.of(context).accentColor
        ))
      ),
    );

    /*GestureDetector(
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
              )*/
  }

  List<Widget> _children(MainModel model) {
    List<Widget> result = [
      //_titleAndActions(model, false),
    ];

    if (model.selectedPlaylist != null && model.selectedPlaylist.messages != null) {
      model.selectedPlaylist.messages.forEach((msg) {
        result.add(MessageCard(
          message: msg,
          playlist: model.selectedPlaylist,
          selected: _selectedMessages.contains(msg),
          onSelect: () {
            _toggleMessageSelection(msg);
          },
        ));
      });
    }

    return result;
  }

  List<Widget> _reorderingAndDeletingChildren(MainModel model) {
    List<Widget> result = [
      //_titleAndActions(model, true),
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
                        showTime: false,
                      ),
                    ),
                    GestureDetector(
                      onTap: () { model.removeMessageFromCurrentPlaylistAtIndex(i); },
                      child: Container(
                        padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 10.0),
                        child: Icon(CupertinoIcons.xmark,
                          color: Theme.of(context).accentColor,
                          size: 30.0,
                        )
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

  void editTitle(Playlist playlist) async {
    String newTitle = await showDialog(
      context: context, 
      builder: (context) => EditPlaylistTitleDialog(
        playlist: playlist,
        originalTitle: playlist?.title,
      ),
    );
    if (newTitle != null) {
      setState(() {
        playlist.title = newTitle;
      });
    }
  }

  Future<void> deletePlaylist({Playlist playlist, Function onDelete}) async {
    bool delete = await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete ${playlist.title}?',
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
      await onDelete(playlist);
      Navigator.of(context).pop();
    }
  }

  void openReorderingList() {
    setState(() {
      _reordering = true;
    });
  }

  Widget _playlistActionsButton({
    Playlist playlist,
    Function onDelete,
    Function addAllToQueue,
    Function setMultipleFavorites}) {
    bool active = false;
    if (playlist != null && playlist.messages != null && playlist.messages.length > 0) {
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
              text: 'Reorder and remove',
            ),
            _playlistAction(
              value: 3,
              active: active,
              icon: Icons.check,
              text: 'Select all',
            ),
          ];
        },
        onSelected: (value) async {
          switch (value) {
            case 0:
              editTitle(playlist);
              break;
            case 1:
              await deletePlaylist(playlist: playlist, onDelete: onDelete);
              break;
            case 2:
              openReorderingList();
              break;
            case 3:
              _selectAll(playlist.messages);
              break;
          }
        },
      ),
    );
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