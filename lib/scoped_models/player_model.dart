import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
//import 'package:path/path.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/player/AudioHandler.dart';

class PlayerModel extends Model {
  VFCAudioHandler _audioHandler;
  final db = MessageDB.instance;
  Message _currentlyPlayingMessage;
  Playlist _currentlyPlayingPlaylist;
  Duration _currentPosition;

  Message get currentlyPlayingMessage => _currentlyPlayingMessage;
  Playlist get currentlyPlayingPlaylist => _currentlyPlayingPlaylist;
  Stream<Duration> get currentPositionStream => AudioService.getPositionStream();
  Duration get currentPosition => _currentPosition;
  Stream<bool> get playing => _audioHandler.playingStream;

  void initialize() async {
    _audioHandler = await AudioService.init(
      builder: () => VFCAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelName: 'Voices for Christ',
        androidEnableQueue: true,
        notificationColor: Colors.indigo[900],
        //notificationColor: Color(0xff002D47),
        androidNotificationIcon: 'mipmap/ic_launcher',
        androidNotificationOngoing: true,
        rewindInterval: Duration(seconds: 15),
        fastForwardInterval: Duration(seconds: 15),
      ),
    );

    _audioHandler.mediaItem.listen((item) async {
      print('current item updated: $item');
      _currentlyPlayingMessage = await messageFromMediaItem(item);
      print('_currentlyPlayingMessage is now $_currentlyPlayingMessage');
      notifyListeners();
    });

    currentPositionStream.listen((position) {
      _currentPosition = position;
      //notifyListeners();
    });
  }

  void play() {
    //if (_currentlyPlayingMessage != null) {
      _audioHandler.play();
    //} else {
    //  print('_currentlyPlayingMessage is null');
    //}
  }

  void pause() {
    _audioHandler.pause();
  }

  void setupPlayer({Message message, Duration position, Playlist playlist}) {
    message ??= _currentlyPlayingMessage; // if no message specified, try working with current message
    if (message == null) {
      return;
    } 
    
    if (message?.id == _currentlyPlayingMessage?.id) {
      // message already playing
      position ??= _currentPosition;
    } else {
      // different message from the one currently playing
      position ??= Duration(seconds: 0);
    }

    if (playlist == null) {
      setQueueToSingleMessage(message, position: position);
    } else {
      int index = playlist.messages.indexOf(message);
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
    _audioHandler.updateQueue(queue);
    _audioHandler.skipToQueueItem(index ?? 0);
    _audioHandler.seekTo(position ?? Duration(seconds: 0));
  }

  Future<void> setInitialMessage() async {
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
  }
}