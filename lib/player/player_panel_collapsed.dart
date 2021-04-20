import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/player/AudioPlayerTask.dart';
import 'package:voices_for_christ/streams/play_stream.dart';

class PlayerPanelCollapsed extends StatefulWidget {
  PlayerPanelCollapsed({Key key}) : super(key: key);

  @override
  _PlayerPanelCollapsedState createState() => _PlayerPanelCollapsedState();
}

class _PlayerPanelCollapsedState extends State<PlayerPanelCollapsed> {
  @override
  void initState() { 
    super.initState();
    //_start();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      child: StreamBuilder(
        stream: playStreamController.stream,
        builder: (context, snapshot) {
          print(snapshot.data);
          if (snapshot.data == true) {
            _play();
          } else if (snapshot.data == false) {
            _pause();
          }
          return Row(
            children: [
              ElevatedButton(onPressed: _start, child: Text('Start')),
              ElevatedButton(onPressed: _stop, child: Text('Stop')),
              ElevatedButton(onPressed: _play, child: Text('Play')),
              ElevatedButton(onPressed: _pause, child: Text('Pause')),
            ]
          );
        },
      ),
    );
  }

  void _start() {
    print('start here');
    /*if (AudioService.running == false || AudioService.running == null) {
      print('starting');
      AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
        androidNotificationChannelName: 'Voices for Christ',
        androidNotificationColor: 0xFF002D47,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
      );
    }*/
  }

  void _stop() {
    print('stopping');
    AudioService.stop();
  }

  void _play() {
    print('playing');
    AudioService.play();
  }

  void _pause() {
    print('pausing');
    AudioService.pause();
  }
}

void _audioPlayerTaskEntryPoint() async {
  //AudioServiceBackground.run(() => AudioPlayerTask());
}