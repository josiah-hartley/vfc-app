import 'package:audio_service/audio_service.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/player/AudioPlayerTask.dart';

void _audioPlayerTaskEntryPoint() async {
  //AudioServiceBackground.run(() => AudioPlayerTask());
}

mixin PlayerModel on Model {
  final db = MessageDB.instance;
  Message _currentlyPlayingMessage;
  Playlist _currentlyPlayingPlaylist;
  bool _isPlaying;
  Duration _position;
  List<MediaItem> _queue;
  int _queueIndex;

  Message get currentlyPlayingMessage => _currentlyPlayingMessage;
  bool get isPlaying => _isPlaying;
  Duration get position => _position;
  List<MediaItem> get queue => _queue;
  int get queueIndex => _queueIndex;

  Future<void> startPlayer() async {
    print('starting AudioService');
    if (AudioService.running) {
      print('AudioService already running');
      return;
    }
    Message _defaultMessage = await db.queryOne(56823);
    var msgJson = _defaultMessage.toMediaItem().toJson();
    //List<Message> _messageQueue = [_defaultMessage];
    /*if (_queue == null || _queue.length < 1) {
      if (_currentlyPlayingMessage == null) {
        // arbitrarily pick a default message: one by Bill MacDonald
        Message _defaultMessage = await db.queryOne(56823);
        addMessageToQueue(message: _defaultMessage);
      } else {
        addMessageToQueue(message: _currentlyPlayingMessage);
      }
    }*/
    try {
      /*await AudioService.start(
        backgroundTaskEntrypoint: _audioPlayerTaskEntryPoint,
        androidNotificationChannelName: 'Voices for Christ',
        androidNotificationColor: 0xFF002D47,
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
        params: {
          'message': msgJson,
        },
      );*/
      print('AudioService successfully started');
    } catch(e) {
      print('error starting AudioService: $e');
    }
    AudioService.play();
  }

  void stop() {
    AudioService.stop();
  }

  void play({Message message, Playlist playlist, Duration position}) async {
    if (message == null) {
      return;
    }

    if (playlist != null && playlist.id != _currentlyPlayingPlaylist?.id) {
      // update queue to specified playlist
      int _locationWithinPlaylist = playlist.messages.indexOf(message);
      if (_locationWithinPlaylist > -1) {
        setQueueToPlaylist(playlist: playlist, startingIndex: _locationWithinPlaylist);
      }
    }

    if (message.id == _currentlyPlayingMessage?.id) {
      if (position != _position) {
        // jump to specified position
        _position = position ?? Duration(seconds: 0);
        try {
          AudioService.seekTo(_position);
        } catch(e) {
          print('Error seeking to specified position: $e');
        }
      }
      if (AudioService.playbackState?.playing != true) {
        // this message is queued up, but paused
        startAudioServiceAndPlay();
      }
    } else {
      _queue = [message.toMediaItem()];
      _queueIndex = 0;
      _position = position ?? Duration(seconds: 0);
      startAudioServiceAndPlay();
    }
  }

  void startAudioServiceAndPlay() async {
    await startPlayer(); // start AudioService if not already running
    try {
      AudioService.play();
    } catch(e) {
      print('Error playing AudioService: $e');
    }
  }

  void pause() {
    AudioService.pause();
  }

  void addMessageToQueue({Message message, int index}) {
    MediaItem _messageMediaItem = message.toMediaItem();
    if (_queue == null) {
      _queue = [];
    }
    try {
      if (index >= 0 && index < _queue.length) {
        _queue.insert(index, _messageMediaItem);
      } else {
        _queue.add(_messageMediaItem);
      }
    } catch(e) {
      _queue.add(_messageMediaItem);
    }
    print('queue[0]: ${_queue[0]}');
  }

  void removeMessageFromQueue({Message message}) {

  }

  void reorderMessageInQueue({int oldIndex, int newIndex}) {

  }

  void setQueueToPlaylist({Playlist playlist, int startingIndex}) {
    _queue = playlist.messages.map((message) => message.toMediaItem()).toList();
    _queueIndex = startingIndex;
  }
}