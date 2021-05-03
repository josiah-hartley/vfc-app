import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
//import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';

class AddToPlaylistDialog extends StatefulWidget {
  AddToPlaylistDialog({Key key, this.message, this.allPlaylists, this.playlistsOriginallyContainingMessage}) : super(key: key);
  final Message message;
  final List<Playlist> allPlaylists;
  final List<Playlist> playlistsOriginallyContainingMessage;

  @override
  _AddToPlaylistDialogState createState() => _AddToPlaylistDialogState();
}

class _AddToPlaylistDialogState extends State<AddToPlaylistDialog> {
  //bool _loading;
  //List<Playlist> _allPlaylists = [];
  //List<Playlist> _playlistsOriginallyContainingMessage = [];
  List<Playlist> _playlistsContainingMessage = [];
  //final db = MessageDB.instance;

  @override
  void initState() {
    super.initState();
    setState(() {
      _playlistsContainingMessage = widget.playlistsOriginallyContainingMessage;
    });
    //loadInitialPlaylistData();
  }

  //Future<void> loadInitialPlaylistData({List<Playlist> allPlaylists, Function getPlaylistsContainingMessage}) async {
  Future<void> loadInitialPlaylistData(List<Playlist> allPlaylists) async {
    /*setState(() {
      _loading = true;
    });*/
    //List<Playlist> all = await db.getAllPlaylistsMetadata();
    //List<Playlist> containing = await db.getPlaylistsContainingMessage(widget.message);
    
    //List<Playlist> containing = await model.playlistsContainingMessage(widget.message);
    setState(() {
      //_loading = false;
      //_allPlaylists = allPlaylists;
      //_playlistsOriginallyContainingMessage = containing;
      //_playlistsContainingMessage = containing;
      _playlistsContainingMessage = widget.playlistsOriginallyContainingMessage;
    });
  }

  Future<void> savePlaylistChanges(MainModel model) async {
    await model.updatePlaylistsContainingMessage(widget.message, _playlistsContainingMessage);
    //reloadCurrentPlaylist();
    if (model.selectedPlaylist != null) {
      int indexOnCurrentPlaylist = model.selectedPlaylist.messages.indexWhere((m) => m.id == widget.message?.id);
      bool wasOnCurrentPlaylist = indexOnCurrentPlaylist > -1;
      bool isNowOnCurrentPlaylist = _playlistsContainingMessage.indexWhere((p) => p.id == model.selectedPlaylist?.id) > -1;
      if (wasOnCurrentPlaylist && !isNowOnCurrentPlaylist) {
        // remove from current playlist
        model.removeMessageFromCurrentPlaylistAtIndex(indexOnCurrentPlaylist);
      } 
      if (!wasOnCurrentPlaylist && isNowOnCurrentPlaylist) {
        // add to current playlist
        model.addMessageToCurrentPlaylist(widget.message);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        /*loadInitialPlaylistData(
          allPlaylists: model.playlists,
          getPlaylistsContainingMessage: model.playlistsContainingMessage,
        );*/
        //loadInitialPlaylistData(model.playlists);
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
                  _title(),
                  _playlistSelector(),
                  _actionButtonRow(
                    model: model,
                  ),
                ],
              ),
            ),
          ),
        );
      }
    );
  }

  Widget _title() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).accentColor.withOpacity(0.6),
            width: 1.0,
          ),
        ),
      ),
      child: Text('Add to Playlist',
        style: TextStyle(
          color: Theme.of(context).accentColor,
          fontSize: 18.0,
        )
      )
    );
  }

  Widget _playlistSelector() {
    /*if (_loading) {
      return Expanded(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }*/
    return Expanded(
      child: Container(
        child: ListView.builder(
          itemCount: widget.allPlaylists?.length,
          itemBuilder: (context, index) {
            return _playlistCheckbox(widget.allPlaylists[index]);
          }
        )
      ),
    );
  }

  Widget _playlistCheckbox(Playlist playlist) {
    int index = _playlistsContainingMessage.indexWhere((p) => p.id == playlist.id);
    bool containsMessage = index > -1;
    return GestureDetector(
      onTap: () {
        setState(() {
          if (containsMessage) {
            _playlistsContainingMessage.removeWhere((p) => p.id == playlist.id);
          } else {
            _playlistsContainingMessage.add(playlist);
          }
        });
      },
      child: Container(
        color: Theme.of(context).backgroundColor.withOpacity(0.05),
        padding: EdgeInsets.symmetric(vertical: 16.0, horizontal: 20.0),
        child: Row(
          children: [
            containsMessage
              ? Icon(CupertinoIcons.checkmark_square_fill,
                color: Theme.of(context).accentColor,
                size: 34.0,
              )
              : Icon(CupertinoIcons.square,
                color: Theme.of(context).accentColor,
                size: 34.0,
              ), 
            Container(
              width: MediaQuery.of(context).size.width - 120.0,
              padding: EdgeInsets.only(left: 20.0),
              child: Text(playlist?.title ?? '',
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 20.0,
                )
              ),
            ),
          ],
        )
      ),
    );
  }

  Widget _actionButtonRow({MainModel model}) {
    return Container(
      padding: EdgeInsets.only(top: 14.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ActionButton(
            text: 'SAVE',
            onPressed: () async {
              await savePlaylistChanges(model);
              Navigator.of(context).pop();
            }
          ),
          ActionButton(
            text: 'CANCEL',
            onPressed: () {
              Navigator.of(context).pop();
            }
          ),
        ],
      ),
    );
  }
}