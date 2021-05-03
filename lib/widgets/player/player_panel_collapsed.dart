import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/reverse_speaker_name.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';

class PlayerPanelCollapsed extends StatefulWidget {
  PlayerPanelCollapsed({Key key, this.panelOpen, this.togglePanel}) : super(key: key);
  final bool panelOpen;
  final Function togglePanel;

  @override
  _PlayerPanelCollapsedState createState() => _PlayerPanelCollapsedState();
}

class _PlayerPanelCollapsedState extends State<PlayerPanelCollapsed> {
  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        if (model.currentlyPlayingMessage == null || widget.panelOpen) {
          return SizedBox(height: 0.0);
        }

        return Container(
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: Theme.of(context).backgroundColor.withOpacity(0.5), width: 1.0),
            )
          ),
          child: Column(
            children: [
              _minimizedProgressBar(
                currentPositionStream: model.currentPositionStream,
                duration: model.duration,
              ),
              Row(
                children: [
                  Container(
                    color: Theme.of(context).bottomAppBarColor,
                    child: IconButton(
                      icon: Icon(CupertinoIcons.chevron_up, color: Colors.white),
                      onPressed: widget.togglePanel,
                    ),
                  ),
                  _titleAndSpeaker(model.currentlyPlayingMessage),
                  _playOrPause(
                    playingStream: model.playingStream,
                    onPlay: model.play,
                    onPause: model.pause,
                  ),
                ],
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _minimizedProgressBar({Stream<Duration> currentPositionStream, Duration duration}) {
    return StreamBuilder(
      stream: currentPositionStream,
      builder: (context, snapshot) {
        Duration currentPosition = snapshot.data ?? Duration(seconds: 0);
        Duration totalLength = duration ?? Duration(seconds: 0);
        double progress = totalLength.inSeconds > 0 
          ? currentPosition.inSeconds / totalLength.inSeconds
          : 0.0;
        return Container(
          height: 4.0,
          child: Row(
            children: [
              Container(
                width: progress * MediaQuery.of(context).size.width,
                color: Colors.white,
              ),
              Expanded(
                child: Container(color: Colors.white.withOpacity(0.5),),
              )
            ],
          ),
        );
      },
    );
  }

  Widget _titleAndSpeaker(Message message) {
    return Expanded(
      child: GestureDetector(
        onTap: widget.togglePanel,
        child: Container(
          height: Constants.COLLAPSED_PLAYBAR_HEIGHT - 5.0,
          //onTap: widget.togglePanel,
          child: Container(
            color: Theme.of(context).bottomAppBarColor,
            alignment: Alignment.centerLeft,
            padding: EdgeInsets.symmetric(vertical: 15.0, horizontal: 0.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(message.title,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).accentTextTheme.headline3,
                  ),
                ),
                Expanded(
                  child: Text(speakerReversedName(message.speaker),
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).accentTextTheme.headline4,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _playOrPause({Stream<bool> playingStream, Function onPlay, Function onPause}) {
    return StreamBuilder(
      stream: playingStream,
      builder: (context, snapshot) {
        bool playing = snapshot.data ?? false;
        return Container(
          color: Theme.of(context).bottomAppBarColor,
          padding: EdgeInsets.only(left: 8.0, right: 16.0),
          child: RawMaterialButton(
            fillColor: Colors.orange[800].withOpacity(0.9),
            child: Icon(playing ? Icons.pause : Icons.play_arrow,
              color: Colors.white,
            ),
            shape: CircleBorder(
              side: BorderSide(
                color: Colors.orange[800].withOpacity(0.9),
                width: 2.0,
              )
            ),
            padding: EdgeInsets.all(5.0),
            constraints: BoxConstraints(),
            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
            splashColor: Colors.transparent,
            onPressed: playing ? onPause : onPlay,
          ),
        );
      }
    );
  }
}