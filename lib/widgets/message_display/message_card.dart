import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/download_class.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
//import 'package:voices_for_christ/scoped_models/main_model.dart';
//import 'package:voices_for_christ/widgets/buttons/download_button_deprecated.dart';
//import 'package:voices_for_christ/widgets/buttons/play_button_deprecated.dart';
//import 'package:voices_for_christ/widgets/buttons/stop_button.dart';
import 'package:voices_for_christ/widgets/dialogs/message_actions_dialog.dart';
import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';
import 'package:voices_for_christ/widgets/player/progress_display_bar.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({Key key, this.message, this.playlist, this.selected, this.onSelect, this.isDownloading, this.downloadTask, this.onCancelDownload, this.showDownloadButton = true}) : super(key: key);
  final Message message;
  final Playlist playlist;
  final bool selected;
  final Function onSelect;
  final bool isDownloading;
  final Download downloadTask;
  final Function onCancelDownload;
  final bool showDownloadButton;

  @override
  Widget build(BuildContext context) {
    List<Widget> _rowChildren = [
      isDownloading == true
      ? downloadProgress(
          context: context,
          task: downloadTask,
          onCancel: onCancelDownload,
        )
      : initialSticker(
          context: context,
          name: message.speaker,
          isFavorite: message.isfavorite == 1, 
          borderColor: Theme.of(context).accentColor,
          borderWidth: message.isdownloaded == 1 ? 2.0 : 1.0,
          selected: selected,
          onSelect: onSelect,
        ),
      Expanded(
        child: messageTitleAndSpeakerDisplay(
          message: message,
          truncateTitle: true,
          textColor: Theme.of(context).accentColor,
        ),
      ),
    ];
    if (showDownloadButton && message.isdownloaded == 0) {
      _rowChildren.add(
        Container(
          child: ScopedModelDescendant<MainModel>(
            builder: (context, child, model) {
              return Container(
                child: message.iscurrentlydownloading == 1
                  ? Container(
                    padding: EdgeInsets.only(top: 6.0, bottom: 6.0, left: 12.0, right: 10.0),
                    width: 40.0,
                    height: 32.0,
                    child: CircularProgressIndicator(strokeWidth: 2.0),
                  )
                  : GestureDetector(
                    onTap: () { model.queueDownloads([message], showPopup: false); },
                    child: Container(
                      color: Theme.of(context).backgroundColor.withOpacity(0.01),
                      padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
                      child: Icon(Icons.download_rounded,
                        color: Theme.of(context).accentColor.withOpacity(0.8),
                      ),
                    ),
                  ),
                  /*IconButton(
                    iconSize: 24.0,
                    color: Theme.of(context).accentColor.withOpacity(0.8),
                    icon: Icon(Icons.download_sharp),
                    onPressed: () { model.queueDownloads([message], showPopup: false); },
                  ),*/
              );
            },
          ),
        )
      );
    }

    return GestureDetector(
      onLongPress: onSelect,
      onTap: () {
        showDialog(
          context: context, 
          builder: (context) {
            return MessageActionsDialog(
              message: message,
              currentPlaylist: playlist,
            );
          }
        );
      },
      child: Container(
        color: selected 
          ? Theme.of(context).accentColor.withOpacity(0.1)
          : Theme.of(context).backgroundColor.withOpacity(0.01),
        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Column(
          children: [
            Row(
              children: _rowChildren,
            ),
            message.isdownloaded == 1 ? 
              ProgressDisplayBar(
                message: message,
                height: 1.5,
                color: Theme.of(context).accentColor,
                unplayedOpacity: 0.06,
              )
              : SizedBox(height: 1.5),
            /*Row(
              children: [
                DownloadButton(message: message),
                PlayButton(message: message),
                StopButton(message: message),
              ],
            ),*/
          ],
        ),
      ),
    );
  }
}