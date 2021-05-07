import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/download_class.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
//import 'package:voices_for_christ/scoped_models/main_model.dart';
//import 'package:voices_for_christ/widgets/buttons/download_button_deprecated.dart';
//import 'package:voices_for_christ/widgets/buttons/play_button_deprecated.dart';
//import 'package:voices_for_christ/widgets/buttons/stop_button.dart';
import 'package:voices_for_christ/widgets/dialogs/message_actions_dialog.dart';
import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';
import 'package:voices_for_christ/widgets/player/progress_display_bar.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({Key key, this.message, this.playlist, this.selected, this.onSelect, this.isDownloading, this.downloadTask, this.onCancelDownload}) : super(key: key);
  final Message message;
  final Playlist playlist;
  final bool selected;
  final Function onSelect;
  final bool isDownloading;
  final Download downloadTask;
  final Function onCancelDownload;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
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
        padding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 6.0),
        child: Column(
          children: [
            Row(
              children: [
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
              ],
            ),
            //message.isdownloaded == 1 ? 
            ProgressDisplayBar(
              message: message,
              height: 1.5,
              color: Theme.of(context).accentColor,
              unplayedOpacity: 0.2,
            )
            //: Container(),
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