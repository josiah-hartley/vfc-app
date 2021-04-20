import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/widgets/message_display/buttons/download_button.dart';
import 'package:voices_for_christ/widgets/message_display/buttons/play_button.dart';
import 'package:voices_for_christ/widgets/message_display/buttons/stop_button.dart';
import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';

class MessageCard extends StatelessWidget {
  const MessageCard({Key key, this.message}) : super(key: key);
  final Message message;

  @override
  Widget build(BuildContext context) {
    return Container(
      child: Column(
        children: [
          Row(
            children: [
              initialSticker(name: message.speaker),
              Expanded(
                child: messageTitleAndSpeakerDisplay(
                  message: message,
                  truncateTitle: true,
                  textColor: Theme.of(context).accentColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              DownloadButton(message: message),
              PlayButton(message: message),
              StopButton(message: message),
            ],
          ),
        ],
      ),
    );
  }
}