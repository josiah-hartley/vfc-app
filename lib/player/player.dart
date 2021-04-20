import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/player/AudioPlayerTask.dart';

class Player extends StatefulWidget {
  Player({Key key}) : super(key: key);

  @override
  _PlayerState createState() => _PlayerState();
}

class _PlayerState extends State<Player> {
  @override
  Widget build(BuildContext context) {
    return Container(
       child: Row(
         children: [
           ElevatedButton(onPressed: _start, child: Text('Start')),
           ElevatedButton(onPressed: _stop, child: Text('Stop')),
           ElevatedButton(onPressed: _play, child: Text('Play')),
           ElevatedButton(onPressed: _pause, child: Text('Pause')),
         ]
       ),
    );
  }

  void _start() {
    print('start here');
    /*AudioService.start(
      backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
      androidNotificationChannelName: 'Voices for Christ',
      androidNotificationColor: 0xFF002D47,
      androidNotificationIcon: 'mipmap/ic_launcher',
      androidNotificationOngoing: true,
    );*/
  }

  void _stop() {
    AudioService.stop();
  }

  void _play() {
    AudioService.play();
  }

  void _pause() {
    AudioService.pause();
  }
}

void _audioPlayerTaskEntryPoint() async {
  //AudioServiceBackground.run(() => AudioPlayerTask());
}