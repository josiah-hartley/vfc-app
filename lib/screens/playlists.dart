import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/new_playlist_dialog.dart';
import 'package:voices_for_christ/widgets/dialogs/playlist_dialog.dart';

class PlaylistsPage extends StatefulWidget {
  PlaylistsPage({Key key}) : super(key: key);

  @override
  _PlaylistsPageState createState() => _PlaylistsPageState();
}

class _PlaylistsPageState extends State<PlaylistsPage> {
  bool _loadingPlaylist = false;
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        /*if (model.playlists.length < 1) {
          return _emptyPage(() { 
            showDialog(
              context: context, 
              builder: (context) {
                return NewPlaylistDialog();
              },
            );
          });
        }*/
        //if (model.selectedPlaylist == null) {
        //model.loadPlaylistsMetadata();
          return _listOfPlaylists(
            playlists: model.playlists,
            onOpenPlaylist: (index) async {
              if (_loadingPlaylist) {
                return;
              }
              // avoid locking database; if one playlist is opening, can't open another
              _loadingPlaylist = true;
              await model.selectPlaylist(model.playlists[index - 1]);
              _loadingPlaylist = false;
              //Playlist p = model.playlists[index - 1];
              //p.messages = await model.loadMessagesOnPlaylist(p);
              await showDialog(
                context: context, 
                builder: (context) {
                  return PlaylistDialog();
                }
              );
            }
          );
        //}
        /*return Container(
          child: Column(
            children: [
              _playlistSelectionBar(),
              _playlistMessageList(),
            ],
          ),
        );*/
      },
    );
  }

  Widget _emptyPage(Function addNewPlaylist) {
    return Container(
      alignment: Alignment.topCenter,
      padding: EdgeInsets.symmetric(
        horizontal: MediaQuery.of(context).size.width / 8, 
        vertical: MediaQuery.of(context).size.height / 4,
      ),
      child: GestureDetector(
        onTap: addNewPlaylist,
        child: Container(
          padding: EdgeInsets.symmetric(horizontal: 14.0, vertical: 14.0),
          decoration: BoxDecoration(
            color: Theme.of(context).accentColor.withOpacity(0.05),
            borderRadius: BorderRadius.circular(14.0),
            border: Border.all(
              color: Theme.of(context).accentColor.withOpacity(0.1),
              width: 2.0,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(CupertinoIcons.add_circled, 
                size: 48.0,
                color: Theme.of(context).accentColor.withOpacity(0.8),
              ),
              SizedBox(width: 12.0),
              Expanded(
                child: Container(
                  child: Text('Create your first playlist',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 26.0,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).accentColor.withOpacity(0.8),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listOfPlaylists({List<Playlist> playlists, Function onOpenPlaylist}) {
    return Container(
      alignment: Alignment.topLeft,
      child: ListView.builder(
        padding: EdgeInsets.only(top: 10.0),
        itemCount: playlists.length + 2,
        itemBuilder: (context, index) {
          if (index == 0) {
            return _playlistCard(
              title: 'Add a new playlist',
              icon: CupertinoIcons.add_circled,
              backgroundColor: Theme.of(context).accentColor.withOpacity(0.1),
              onPressed: () {
                showDialog(
                  context: context, 
                  builder: (context) {
                    return NewPlaylistDialog();
                  },
                );
              },
            );
          }
          if (index == playlists.length + 1) {
            return SizedBox(height: 250.0);
          }
          return _playlistCard(
            title: playlists[index - 1]?.title,
            icon: CupertinoIcons.list_dash,
            onPressed: () {
              onOpenPlaylist(index);
            },
          );
        }
      )
    );
  }

  Widget _playlistCard({String title, IconData icon, Color backgroundColor, Function onPressed}) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        color: backgroundColor == null ? Colors.transparent : backgroundColor,
        padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 14.0),
        child: Row(
          children: [
            Container(
              child: Icon(icon,
                color: Theme.of(context).accentColor,
                size: 30.0,
              ),
            ),
            Expanded(
              child: Container(
                padding: EdgeInsets.only(left: 20.0),
                child: Text(title ?? '',
                  style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontSize: 20.0,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _playlistSelectionBar({Playlist currentPlaylist, Function addNewPlaylist}) {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 12.0),
      child: Row(
        children: [
          Expanded(
            child: TextButton(
              child: Container(
                alignment: Alignment.centerLeft,
                decoration: BoxDecoration(
                  color: Theme.of(context).accentColor.withOpacity(1.0),
                  borderRadius: BorderRadius.circular(6.0),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(currentPlaylist?.title ?? 'Current Playlist is a long one with a long title',
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).primaryColor,
                          fontSize: 18.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    Icon(CupertinoIcons.chevron_down,
                      size: 16.0,
                      color: Theme.of(context).primaryColor,
                    ),
                  ],
                ),
              ),
              onPressed: () { },
            ),
            //child: Container(
              
              /*width: MediaQuery.of(context).size.width - 150.0,
              decoration: BoxDecoration(
                color: Theme.of(context).accentColor.withOpacity(0.8),
                borderRadius: BorderRadius.circular(6.0),
              ),
              padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
              child: Text(currentPlaylist?.title ?? 'Current Playlist is a long one with a long title',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Theme.of(context).primaryColor,
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),*/
            //),
          ),
          IconButton(
            icon: Icon(CupertinoIcons.add_circled,
              size: 30.0,
              color: Theme.of(context).accentColor,
            ), 
            onPressed: addNewPlaylist,
          ),
          IconButton(
            icon: Icon(CupertinoIcons.ellipsis_vertical,
              size: 30.0,
              color: Theme.of(context).accentColor,
            ),
            onPressed: addNewPlaylist,
          ),
        ],
      ),
    );
  }

  Widget _playlistMessageList() {
    return Expanded(
      child: Container(),
    );
  }
}