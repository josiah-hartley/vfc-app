import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';

class ProgressDisplayBar extends StatelessWidget {
  const ProgressDisplayBar({Key key, this.message, this.height, this.color = Colors.white, this.unplayedOpacity = 0.3}) : super(key: key);
  final Message message;
  final double height;
  final Color color;
  final double unplayedOpacity;

  @override
  Widget build(BuildContext context) {
    if (message == null) {
      return Container();
    }
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        if (message?.id == model.currentlyPlayingMessage?.id) {
          return StreamBuilder(
            stream: model.currentPositionStream,
            builder: (context, snapshot) {
              Duration currentPosition = snapshot.data ?? Duration(seconds: 0);
              Duration totalLength = model.duration ?? Duration(seconds: 0);
              double progress = totalLength.inSeconds > 0 
                ? currentPosition.inSeconds / totalLength.inSeconds
                : 0.0;
              return _progressBar(
                context: context,
                height: height,
                progress: progress,
              );
            },
          );
        }
        double lastPlayedSeconds = message?.lastplayedposition ?? 0.0;
        double totalSeconds = message?.durationinseconds ?? 0.0;
        double progress = totalSeconds > 0 
          ? lastPlayedSeconds / totalSeconds
          : 0.0;
        return _progressBar(
          context: context,
          height: height,
          progress: progress,
        );
      }
    );
  }

  Widget _progressBar({BuildContext context, double height, double progress}) {
    int flexPlayed = (progress * 100).round();
    int flexUnplayed = 100 - flexPlayed;
    return Container(
      height: height,
      child: Row(
        children: [
          Expanded(
            flex: flexPlayed,
            child: Container(color: color),
          ),
          Expanded(
            flex: flexUnplayed,
            child: Container(color: color.withOpacity(unplayedOpacity)),
          )
        ],
      ),
    );
  }
}