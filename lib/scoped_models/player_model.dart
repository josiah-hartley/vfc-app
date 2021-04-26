import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/player/AudioHandler.dart';

mixin PlayerModel on Model {
  VFCAudioHandler _audioHandler;
  SharedPreferences _prefs;
  final db = MessageDB.instance;
  List<Message> _queue;
  int _queueIndex;
  Message _currentlyPlayingMessage;
  Playlist _currentlyPlayingPlaylist;
  Duration _currentPosition;
  Duration _duration = Duration(seconds: 0);
  double _playbackSpeed = 1.0;

  List<Message> get queue => _queue;
  int get queueIndex => _queueIndex;
  Message get currentlyPlayingMessage => _currentlyPlayingMessage;
  Playlist get currentlyPlayingPlaylist => _currentlyPlayingPlaylist;
  Stream<Duration> get currentPositionStream => AudioService.getPositionStream();
  Duration get currentPosition => _currentPosition;
  Duration get duration => _duration;
  Stream<bool> get playingStream => _audioHandler.playingStream;
  double get playbackSpeed => _playbackSpeed;

  void initializePlayer() async {
    _audioHandler = await AudioService.init(
      builder: () => VFCAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelName: 'Voices for Christ',
        androidEnableQueue: true,
        //notificationColor: Colors.indigo[900],
        notificationColor: Color(0xff002D47),
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
        rewindInterval: Duration(seconds: 15),
        fastForwardInterval: Duration(seconds: 15),
      ),
    );

    _audioHandler.queue.listen((updatedQueue) async {
      _queue = [];
      for (int i = 0; i < updatedQueue.length; i++) {
        MediaItem item = updatedQueue[i];
        Message message = await messageFromMediaItem(item);
        _queue.add(message);
      }
      notifyListeners(); // TODO: deal with lag
    });

    _audioHandler.mediaItem.listen((item) async {
      // save position on previous message
      /*if (_currentlyPlayingMessage != null && currentPosition != null) {
        _currentlyPlayingMessage.lastplayedposition = currentPosition.inSeconds.toDouble();
        print('updating LAST PLAYED POSITION: $currentPosition');
        await db.update(_currentlyPlayingMessage);
      }*/

      _currentlyPlayingMessage = await messageFromMediaItem(item);
      saveLastPlayedMessage();
      _queueIndex = _queue.indexWhere((message) => message.id == _currentlyPlayingMessage.id) ?? 0;
      notifyListeners();
    });

    currentPositionStream.listen((position) async {
      _currentPosition = position;

      if (_currentlyPlayingMessage != null && (position.inSeconds.toDouble() - _currentlyPlayingMessage.lastplayedposition).abs() > 15) {
        _currentlyPlayingMessage.lastplayedposition = position.inSeconds.toDouble();
        await db.update(_currentlyPlayingMessage);
      }
      //notifyListeners();
    });

    _audioHandler.durationStream.listen((updatedDuration) {
      _duration = updatedDuration;
      notifyListeners();
    });

    _audioHandler.playbackState.listen((playbackState) async {
      _playbackSpeed = playbackState.speed;
      notifyListeners();
    });

    /*_audioHandler.playerStateStream.listen((playerState) {
      print('PLAYER STATE CHANGING');
    });*/

    loadLastPlayedMessage();
    loadLastPlaybackSpeed();
  }

  void saveLastPlayedMessage() async {
    if (_currentlyPlayingMessage?.id != null) {
      _prefs = await SharedPreferences.getInstance();
      _prefs.setInt('mostRecentMessageId', _currentlyPlayingMessage?.id);
    }
  }

  void loadLastPlayedMessage() async {
    _prefs = await SharedPreferences.getInstance();
    int _currMessageId = _prefs.getInt('mostRecentMessageId');
    if (_currMessageId != null) {
      Message result = await db.queryOne(_currMessageId);
      double _seconds = result?.lastplayedposition ?? 0.0;
      int _milliseconds = (_seconds * 1000).round();
      setupPlayer(
        message: result, 
        position: Duration(milliseconds: _milliseconds),
      );
    }
  }

  void play() {
    _audioHandler.play();
  }

  void pause() {
    _audioHandler.pause();
  }

  Future<void> setupPlayer({Message message, Duration position, Playlist playlist}) async {
    message ??= _currentlyPlayingMessage; // if no message specified, try working with current message
    if (message == null || message.isdownloaded != 1) {
      return;
    }

    // reload message in case anything has changed
    Message result = await db.queryOne(message.id);
    double _seconds = result?.lastplayedposition ?? 0.0;
    int _milliseconds = (_seconds * 1000).round();
    position ??= Duration(milliseconds: _milliseconds);
    
    if (message?.id == _currentlyPlayingMessage?.id) {
      // message already playing
      position ??= _currentPosition;
    } else {
      // different message from the one currently playing
      // if another message is playing, save its position
      /*if (_currentlyPlayingMessage != null) {
        _currentlyPlayingMessage.lastplayedposition = currentPosition.inSeconds.toDouble();
        print('SAVING LAST PLAYED POSITION: ${currentPosition.inSeconds}');
        await db.update(_currentlyPlayingMessage);
      }*/
      // reload message in case anything has changed
      /*Message result = await db.queryOne(message?.id);
      int _milliseconds = ((result?.lastplayedposition ?? 0.0) * 1000).round();
      position ??= Duration(milliseconds: _milliseconds);*/
      position ??= Duration(seconds: 0);
    }

    if (playlist == null) {
      setQueueToSingleMessage(message, position: position);
    } else {
      int index = playlist.messages.indexWhere((item) => item?.id == message?.id);
      setQueueToPlaylist(playlist, index: index, position: position);
    }
  }

  void setQueueToSingleMessage(Message message, {Duration position}) {
    MediaItem mediaItem = message.toMediaItem();
    setupQueue(queue: [mediaItem], position: position, index: 0);
  }

  void setQueueToPlaylist(Playlist playlist, {int index, Duration position}) {
    List<MediaItem> mediaItems = playlist.toMediaItemList();
    setupQueue(queue: mediaItems, position: position, index: index);
  }

  void setupQueue({List<MediaItem> queue, Duration position, int index}) async {
    Message _previousMessage = _currentlyPlayingMessage;
    Duration _previousPosition = _currentPosition;

    await _audioHandler.updateQueue(queue);
    await _audioHandler.seekTo(position ?? Duration(seconds: 0), index: index ?? 0);
  
    if (_previousMessage != null && _previousPosition != null) {
      _previousMessage.lastplayedposition = _previousPosition.inSeconds.toDouble();
      await db.update(_previousMessage);
    }
  }

  void addToQueue(Message message, {int index}) {
    if (index == null) {
      _audioHandler.addQueueItem(message.toMediaItem());
    } else {
      _audioHandler.insertQueueItem(index, message.toMediaItem());
    }
  }

  void removeFromQueue(int index) {
    _audioHandler.removeQueueItemAt(index);
  }

  void changeQueuePosition({int oldIndex, int newIndex}) {
    if (oldIndex == null || newIndex == null || oldIndex == newIndex) {
      return;
    }
    if (oldIndex < 0 || newIndex < 0 || oldIndex >= _queue.length || newIndex >= _queue.length) {
      return;
    }
    MediaItem mediaItem = _queue[oldIndex].toMediaItem();
    _audioHandler.removeQueueItemAt(oldIndex);
    _audioHandler.insertQueueItem(newIndex, mediaItem);
  }

  /*Future<void> setInitialMessage() async {
    Message _defaultMessage = await db.queryOne(56823);
    MediaItem item = MediaItem(
      album: 'Will Mac',
      title: _defaultMessage?.title ?? 'default title',
      id: _defaultMessage?.filepath ?? 'https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3',
      extras: {
        'messageId': 56823,
      }
    );
    _audioHandler.updateQueue([item]);
    _audioHandler.skipToQueueItem(0);
  }*/

  void seekToSecond(double seconds) {
    int milliseconds = (seconds * 1000).round();
    _audioHandler.seekTo(Duration(milliseconds: milliseconds));
  }

  void seekForwardFifteenSeconds() {
    if (_currentlyPlayingMessage.durationinseconds.toInt() - currentPosition.inSeconds > 15) {
      seekToSecond(currentPosition.inSeconds.toDouble() + 15.0);
    } else {
      seekToSecond(_currentlyPlayingMessage.durationinseconds.toDouble());
    }
  }

  void seekBackwardFifteenSeconds() {
    if (currentPosition.inSeconds >= 15) {
      seekToSecond(currentPosition.inSeconds.toDouble() - 15.0);
    } else {
      seekToSecond(0.0);
    }
  }

  void skipPrevious() {
    _audioHandler.skipToPrevious();
  }

  void skipNext() {
    _audioHandler.skipToNext();
  }

  void setSpeed(double speed) async {
    _audioHandler.setSpeed(speed);
    _prefs = await SharedPreferences.getInstance();
    _prefs.setDouble('playbackSpeed', speed ?? 1.0);
  }

  void loadLastPlaybackSpeed() async {
    _prefs = await SharedPreferences.getInstance();
    double speed = _prefs.getDouble('playbackSpeed') ?? 1.0;
    setSpeed(speed);
  }
}