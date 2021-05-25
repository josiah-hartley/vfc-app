import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
//import 'package:fluttertoast/fluttertoast.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/add_to_playlist_dialog.dart';
import 'package:voices_for_christ/widgets/dialogs/download_before_playing_dialog.dart';
import 'package:voices_for_christ/widgets/dialogs/more_message_details_dialog.dart';
import 'package:voices_for_christ/widgets/player/progress_display_bar.dart';

class MessageActionsDialog extends StatefulWidget {
  MessageActionsDialog({Key key, this.message, this.currentPlaylist}) : super(key: key);
  final Message message;
  final Playlist currentPlaylist;

  @override
  _MessageActionsDialogState createState() => _MessageActionsDialogState();
}

class _MessageActionsDialogState extends State<MessageActionsDialog> {
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
              padding: EdgeInsets.symmetric(vertical: 40.0, horizontal: 0.0),
              child: ListView(
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
    bool _isDownloaded = widget.message?.isdownloaded == 1 && widget.message?.filepath != '';
    int _indexInQueue = model.queue.indexWhere((m) => m.id == widget.message?.id);
    return [
      _title(),
      //_progress(model),
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16.0),
        child: ProgressDisplayBar(
          message: widget.message,
          height: 3.0,
          color: Theme.of(context).accentColor,
          unplayedOpacity: 0.3,
        ),
      ),
      _playAction(
        model: model,
        message: widget.message,
      ),
      _downloadAction(
        model: model,
        message: widget.message,
      ),
      _action(
        icon: Icons.playlist_add,
        color: Theme.of(context).accentColor,
        text: 'Add to Playlist',
        onPressed: () async {
          List<Playlist> containing = await model.playlistsContainingMessage(widget.message);
          showDialog(
            context: context, 
            builder: (context) {
              return AddToPlaylistDialog(
                message: widget.message,
                playlistsOriginallyContainingMessage: containing,
              );
            }
          );
        }
      ),
      _action(
        icon: CupertinoIcons.list_dash,
        color: _isDownloaded 
          ? Theme.of(context).accentColor 
          : Theme.of(context).accentColor.withOpacity(0.5),
        iconSize: 30.0,
        text: _indexInQueue > -1 ? 'Remove from Queue' : 'Add to Queue',
        onPressed: _isDownloaded
          ? () {
            if (_indexInQueue > -1) {
              model.removeFromQueue(_indexInQueue);
              showToast('Removed from Queue');
            } else {
              model.addToQueue(widget.message);
              showToast('Added to Queue');
            }
          }
          : null,
      ),
      _action(
        icon: widget.message.isfavorite == 1 ? CupertinoIcons.star_fill : CupertinoIcons.star,
        color: Theme.of(context).accentColor,
        iconSize: 30.0,
        text: widget.message.isfavorite == 1 ? 'Favorite' : 'Add to Favorites',
        onPressed: () async {
          //print(widget.message.title);
          await model.toggleFavorite(widget.message);
        }
      ),
      _action(
        icon: widget.message.isplayed == 1 ? CupertinoIcons.check_mark_circled_solid : CupertinoIcons.check_mark_circled,
        color: Theme.of(context).accentColor,
        iconSize: 30.0,
        text: widget.message.isplayed == 1 ? 'Played' : 'Mark as Played',
        onPressed: () async {
          if (widget.message.isplayed == 1) {
            await model.setMessageUnplayed(widget.message);
          } else {
            await model.setMessagePlayed(widget.message);
          }
        }
      ),
      _action(
        icon: CupertinoIcons.info,
        color: Theme.of(context).accentColor,
        iconSize: 30.0,
        text: 'More Details',
        onPressed: () {
          showDialog(
            context: context, 
            builder: (context) => MoreMessageDetailsDialog(message: widget.message),
          );
        }
      ),
    ];
  }

  Widget _title() {
    return Container(
      padding: EdgeInsets.only(bottom: 14.0),
      child: Row(
        children: [
          /*Container(
            child: IconButton(
              icon: Icon(CupertinoIcons.back),
              iconSize: 34.0,
              color: Theme.of(context).accentColor,
              onPressed: () { Navigator.of(context).pop(); },
            ),
          ),*/
          GestureDetector(
            child: Container(
              color: Theme.of(context).backgroundColor.withOpacity(0.01),
              padding: EdgeInsets.only(left: 28.0, right: 28.0, top: 24.0, bottom: 24.0),
              child: Icon(CupertinoIcons.back, 
                size: 34.0,
                color: Theme.of(context).accentColor
              ),
            ),
            onTap: () { Navigator.of(context).pop(); },
          ),
          Expanded(
            child: Container(
              padding: EdgeInsets.only(right: 16.0),
              child: Column(
                children: [
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(widget.message.title,
                      style: Theme.of(context).primaryTextTheme.headline1.copyWith(
                        fontSize: 20.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(vertical: 10.0),
                    child: Text(widget.message.speaker,
                      style: Theme.of(context).primaryTextTheme.headline2.copyWith(
                        fontSize: 18.0,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                ],
              ),
            ),
          ),
        ],
      ),
      /*decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Theme.of(context).accentColor
        ))
      ),*/
    );
  }

  /*Widget _progress(MainModel model) {
    if (widget.message?.id == model.currentlyPlayingMessage?.id) {
      return StreamBuilder(
        stream: model.currentPositionStream,
        builder: (context, snapshot) {
          Duration currentPosition = snapshot.data ?? Duration(seconds: 0);
          Duration totalLength = model.duration ?? Duration(seconds: 0);
          double progress = totalLength.inSeconds > 0 
            ? currentPosition.inSeconds / totalLength.inSeconds
            : 0.0;
          return _progressBar(progress);
        },
      );
    }
    double lastPlayedSeconds = widget.message?.lastplayedposition ?? 0.0;
    double totalSeconds = widget.message?.durationinseconds ?? 0.0;
    double progress = totalSeconds > 0 
      ? lastPlayedSeconds / totalSeconds
      : 0.0;
    return _progressBar(progress);
    /*return Container(
      child: Text(widget.message.lastplayedposition.toString()),
    );*/
  }*/

  /*Widget _progressBar(double progress) {
    return Container(
      height: 3.0,
      child: Row(
        children: [
          Container(
            width: progress * MediaQuery.of(context).size.width,
            color: Theme.of(context).accentColor,
          ),
          Expanded(
            child: Container(color: Theme.of(context).accentColor.withOpacity(0.3),),
          )
        ],
      ),
    );
  }*/

  Widget _action({IconData icon, double iconSize, Color color, String text, Function onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        splashColor: Theme.of(context).accentColor,
        borderRadius: BorderRadius.circular(0.0),
        child: Container(
          padding: EdgeInsets.symmetric(vertical: 20.0, horizontal: 16.0),
          child: Row(
            children: [
              Container(
                width: 65.0,
                alignment: Alignment.center,
                margin: EdgeInsets.only(right: 12.0),
                child: Icon(icon,
                  color: color,
                  size: iconSize ?? 34.0,
                ),
              ),
              Expanded(
                child: Text(text,
                  style: TextStyle(
                    color: color,
                    fontSize: 18.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          )
        ),
      ),
    );
  }

  Widget _playAction({MainModel model, Message message}) {
    if (message.isdownloaded != 1) {
      return _action(
        icon: CupertinoIcons.play,
        color: Theme.of(context).accentColor.withOpacity(0.5),
        iconSize: 30.0,
        text: 'Play',
        onPressed: () {
          showDialog(
            context: context, 
            builder: (context) => DownloadBeforePlayingDialog(onDownload: () {
              model.queueDownloads([message]);
            }),
          );
        },
      );
    }

    if (message?.id == model.currentlyPlayingMessage?.id) {
      return StreamBuilder<bool>(
        stream: model.playingStream,
        builder: (context, snapshot) {
          bool isPlaying = snapshot.data ?? false;
          return _action(
            icon: isPlaying ? CupertinoIcons.pause : CupertinoIcons.play_fill,
            color: Theme.of(context).accentColor,
            iconSize: 30.0,
            text: isPlaying ? 'Pause' : 'Play',
            onPressed: () {
              if (isPlaying) {
                model.pause();
              } else {
                model.play();
              }
            }
          );
        },
      );
    }

    return _action(
      icon: CupertinoIcons.play_fill,
      color: Theme.of(context).accentColor,
      iconSize: 30.0,
      text: 'Play',
      onPressed: () async {
        //int _milliseconds = ((widget.message?.lastplayedposition ?? 0.0) * 1000).round();
        await model.setupPlayer(
          message: widget.message,
          playlist: widget.currentPlaylist,
          //position: Duration(milliseconds: _milliseconds),
        );
        model.play();
      }
    );
  }

  Widget _downloadAction({MainModel model, Message message}) {
    if (message?.isdownloaded == 1) {
      return _action(
        icon: CupertinoIcons.delete,
        color: Theme.of(context).accentColor,
        iconSize: 30.0,
        text: 'Remove Download',
        onPressed: () async {
          if (message?.id != model.currentlyPlayingMessage?.id) {
            await model.deleteMessages([message]);
          } else {
            showToast('Cannot delete while message is playing');
          }
        }
      );
    }

    if (message?.iscurrentlydownloading == 1) {
      return Container(
        padding: EdgeInsets.symmetric(vertical: 24.0, horizontal: 16.0),
        child: Row(
          children: [
            Container(
              width: 65.0,
              alignment: Alignment.center,
              margin: EdgeInsets.only(right: 12.0),
              child: CircularProgressIndicator(),
            ),
            Expanded(
              child: Text('Downloading...',
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 20.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        )
      );
    }

    return _action(
      icon: Icons.download_sharp,
      color: Theme.of(context).accentColor,
      iconSize: 34.0,
      text: 'Download',
      onPressed: () async {
        //await model.downloadMessage(message);
        
        model.queueDownloads([message]);
      }
    );
  }
}