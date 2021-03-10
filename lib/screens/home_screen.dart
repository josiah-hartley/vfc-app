import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/player/player.dart';

class HomeScreen extends StatefulWidget {
  HomeScreen({Key key}) : super(key: key);

  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  List<Message> _messages = [];
  AudioPlayer _player = AudioPlayer();

  @override
  void initState() {
    super.initState();
    loadMessages();
  }

  void loadMessages() async {
    final db = MessageDB.instance;
    List<Message> results = await db.searchBySpeakerOrTitle('Josiah Hartley');
    setState(() {
      _messages = results;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Home Screen')
      ),
      body: Container(
        child: Center(
          child: Player(),
          /*child: ListView.builder(
            itemCount: _messages.length,
            itemBuilder: (context, index) {
              return _messageDisplay(_messages[index]);
            },
          )*/
        )
      )
    );
  }

  Widget _messageDisplay(Message message) {
    return Container(
      child: Column(
        children: [
          Text(message.title),
          Text(message.speaker),
          Row(
            children: [
              FlatButton(
                child: Text('Play'),
                onPressed: () { _play(message); },
              ),
              FlatButton(
                child: Text('Pause'),
                onPressed: () { _pause(message); },
              )
            ],
          )
        ]
      )
    );
  }

  void _play(Message message) {
    print(message.url);
    try {
      _player.setUrl(message.url);
      _player.play();
    } catch (e) {
      print(e);
    }
  }

  void _pause(Message message) {
    _player.pause();
  }
}