import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/player_model.dart';
import 'package:voices_for_christ/streams/play_stream.dart';

class PlayButton extends StatelessWidget {
  const PlayButton({Key key, this.message}) : super(key: key);
  final Message message;

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<PlayerModel>(
      builder: (context, child, model) {
        return Container(
          child: TextButton(
            child: Text('Play'),
            onPressed: () { 
              model.setupPlayer(message: message);
              model.play();
            }
            //onPressed: _play,
          ),
        );
      }
    );
  }

  void _play() {
    print(message.title);
    playStreamController.add(true);
  }
}