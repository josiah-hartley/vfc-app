import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/helpers/playable_queue.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/helpers/logger.dart' as Logger;
import 'package:voices_for_christ/player/AudioHandler.dart';

mixin PlayerModel on Model {
  VFCAudioHandler _audioHandler;
  SharedPreferences _prefs;
  final db = MessageDB.instance;
  bool _playerVisible = false;
  List<Message> _queue;
  int _queueIndex;
  Message _currentlyPlayingMessage;
  Playlist _currentlyPlayingPlaylist;
  Duration _currentPosition;
  Duration _duration = Duration(seconds: 0);
  double _playbackSpeed = 1.0;

  bool get playerVisible => _playerVisible;
  List<Message> get queue => _queue;
  int get queueIndex => _queueIndex;
  Message get currentlyPlayingMessage => _currentlyPlayingMessage;
  Playlist get currentlyPlayingPlaylist => _currentlyPlayingPlaylist;
  Stream<Duration> get currentPositionStream => AudioService.getPositionStream();
  Duration get currentPosition => _currentPosition;
  Duration get duration => _duration;
  Stream<bool> get playingStream => _audioHandler.playingStream;
  double get playbackSpeed => _playbackSpeed;

  void initializePlayer({Function onChangedMessage}) async {
    _audioHandler = await AudioService.init(
      builder: () => VFCAudioHandler(),
      config: AudioServiceConfig(
        androidNotificationChannelName: 'Voices for Christ',
        androidEnableQueue: true,
        notificationColor: Color(0xff002D47),
        androidNotificationIcon: 'mipmap/ic_launcher_notification',
        androidNotificationOngoing: true,
        rewindInterval: Duration(seconds: 15),
        fastForwardInterval: Duration(seconds: 15),
      ),
    );

    await loadLastPlayedMessage();
    loadLastPlaybackSpeed();

    _audioHandler.queue.listen((updatedQueue) async {
      _queue = updatedQueue.map((item) => messageFromMediaItem(item)).toList();
      notifyListeners();
      if (_queue.length > 0) {
        Logger.logEvent(event: 'Updating queue in database: $_queue');
        await db.reorderAllMessagesInPlaylist(Playlist(Constants.QUEUE_PLAYLIST_ID, 0, 'Queue', []), _queue);
      }
    });

    _audioHandler.mediaItem.listen((item) async {
      _currentlyPlayingMessage = messageFromMediaItem(item);
      if (_currentlyPlayingMessage != null) {
        _currentlyPlayingMessage.lastplayeddate = DateTime.now().millisecondsSinceEpoch;
        await db.update(_currentlyPlayingMessage);
      }
      saveLastPlayedMessage();
      _queueIndex = _queue.indexWhere((message) => message.id == _currentlyPlayingMessage?.id) ?? 0;
      notifyListeners();
    });

    currentPositionStream.listen((position) async {
      _currentPosition = position;

      if (_currentlyPlayingMessage != null && (position.inSeconds.toDouble() - _currentlyPlayingMessage.lastplayedposition).abs() > 15) {
        _currentlyPlayingMessage.lastplayedposition = position.inSeconds.toDouble();
        if ((_currentlyPlayingMessage.durationinseconds - position.inSeconds.toDouble()).abs() < 60) {
          _currentlyPlayingMessage.isplayed = 1;
        }
        await db.update(_currentlyPlayingMessage);
        onChangedMessage(_currentlyPlayingMessage);
        notifyListeners();
      }
    });

    _audioHandler.durationStream.listen((updatedDuration) {
      _duration = updatedDuration;
      notifyListeners();
    });

    _audioHandler.playbackState.listen((playbackState) async {
      _playbackSpeed = playbackState.speed;
      print('PLAYBACK STATE CHANGING: $playbackState');
      bool queueFinished = playbackState?.processingState == AudioProcessingState.completed;
      if (queueFinished) {
        print('DISPOSING: _queueIndex is $_queueIndex and _queue is $_queue');
        disposePlayer();
      }
      notifyListeners();
    });
  }

  void saveLastPlayedMessage() async {
    if (_currentlyPlayingMessage?.id != null) {
      _prefs = await SharedPreferences.getInstance();
      _prefs.setInt('mostRecentMessageId', _currentlyPlayingMessage?.id);
    }
  }

  Future<void> loadLastPlayedMessage() async {
    _prefs = await SharedPreferences.getInstance();
    int _currMessageId = _prefs.getInt('mostRecentMessageId');
    if (_currMessageId != null) {
      Playlist savedQueue = Playlist(Constants.QUEUE_PLAYLIST_ID, 0, 'Queue', []);
      savedQueue.messages = await db.getMessagesOnPlaylist(savedQueue);

      Logger.logEvent(event: 'Loading last played queue: ${savedQueue.messages}');

      Message result = await db.queryOne(_currMessageId);
      double _seconds = result?.lastplayedposition ?? 0.0;
      int _milliseconds = (_seconds * 1000).round();
      await setupPlayer(
        message: result, 
        playlist: savedQueue,
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
    Logger.logEvent(event: 'Setting up player: message: $message, position: $position, playlist: $playlist');
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
    }

    if (playlist == null) {
      setQueueToSingleMessage(message, position: position);
    } else {
      int index = playlist.messages.indexWhere((item) => item?.id == message?.id);
      if (index > -1) {
        setQueueToPlaylist(playlist, index: index, position: position);
      } else {
        setQueueToSingleMessage(message, position: position);
      }
    }

    _playerVisible = true;
    notifyListeners();
  }

  Future<void> setQueueToSingleMessage(Message message, {Duration position}) async {
    MediaItem mediaItem = message.toMediaItem();
    Logger.logEvent(event: 'Setting queue to single message at position $position; media item is $mediaItem');
    await setupQueue(queue: [mediaItem], position: position, index: 0);
  }

  Future<void> setQueueToPlaylist(Playlist playlist, {int index, Duration position}) async {
    if (playlist.messages.length < 1) {
      return;
    }
    if (index == null || index < 0 || index >= playlist.messages.length) {
      index = 0;
    }
    List<MediaItem> mediaItems = playlist.toMediaItemList();
    Logger.logEvent(event: 'Setting queue to playlist at index $index and position $position'); //index in playable queue is $queueIndex, and playable queue is $playableQueue');
    await setupQueue(queue: mediaItems, position: position, index: index);
  }

  Future<void> setupQueue({List<MediaItem> queue, Duration position, int index}) async {
    Logger.logEvent(event: 'Setting up queue at index $index and position $position; queue is $queue');
    Message _previousMessage = _currentlyPlayingMessage;
    Duration _previousPosition = _currentPosition;

    bool didUpdateQueue = await updateQueue(
      queue: queue,
      index: index,
    );
    if (didUpdateQueue) {
      await _audioHandler.seekTo(position: position ?? Duration(seconds: 0));
      
      // save position on previous message
      if (_previousMessage != null && _previousPosition != null) {
        _previousMessage.lastplayedposition = _previousPosition.inSeconds.toDouble();
        await db.update(_previousMessage);
      }
    }
  }

  Future<bool> updateQueue({List<MediaItem> queue, int index}) async {
    Logger.logEvent(event: 'Setting up queue at index $index; queue is $queue');
    if (queue == null || queue.length < 1) {
      return false;
    }
    index ??= _queueIndex;
    if (index == null || index < 0 || index >= queue.length) {
      index = 0;
    }

    // only add downloaded items
    MediaItem _startingMessage = queue[index];
    List<MediaItem> validQueue = await playableQueue(queue);
    int validQueueIndex = validQueue.indexWhere((item) => item.id == _startingMessage?.id);
    if (validQueueIndex < 0) {
      validQueueIndex = 0;
    }
    Logger.logEvent(event: 'Playable queue is $validQueue');

    if (validQueue.length > 0) {
      await _audioHandler.updateQueue(validQueue, index: validQueueIndex);
      if (!_playerVisible) {
        _playerVisible = true;
        notifyListeners();
      }
      return true;
    }
    return false;
  }

  void updateFutureQueue(List<Message> futureQueue) async {
    // replace everything after current message with futureQueue
    int index = _queue.indexWhere((m) => m.id == _currentlyPlayingMessage?.id);
    if (index > -1) {
      _queue.replaceRange(index + 1, _queue.length, futureQueue);
      List<MediaItem> mediaItems = _queue.map((message) => message.toMediaItem()).toList();
      await updateQueue(queue: mediaItems, index: index);
    }
  }

  void addToQueue(Message message) async {
    Logger.logEvent(event: 'Adding $message to queue');
    MediaItem mediaItem = message.toMediaItem();
    if (await mediaItemIsPlayable(mediaItem)) {
      _audioHandler.addQueueItem(mediaItem);
    }

    if (!_playerVisible) {
      _playerVisible = true;
      notifyListeners();
    }
  }

  void addMultipleMessagesToQueue(List<Message> messages) async {
    print('adding messages to queue: _queueIndex is $_queueIndex and _queue is $_queue');
    Logger.logEvent(event: 'Adding $messages to queue');
    List<Message> playedQueue = [];
    List<Message> currentAndFutureQueue = [];
    
    if (_queue != null && _queueIndex != null && _queueIndex > -1 && _queueIndex < _queue.length) {
      // trim played messages from the queue
      // leave at most n messages before the current one
      if (_queueIndex > Constants.QUEUE_BACKLOG_SIZE) {
        playedQueue = _queue.sublist(_queueIndex - Constants.QUEUE_BACKLOG_SIZE, _queueIndex);
      } else {
        playedQueue = _queue.sublist(0, _queueIndex);
      }
      currentAndFutureQueue = _queue.sublist(_queueIndex);
    }

    // remove any of the added messages from the played queue, so that they can be added again
    List<int> messageIdsToAdd = messages.map((m) => m.id).toList();
    playedQueue.removeWhere((m) => messageIdsToAdd.contains(m.id));

    _queue = playedQueue
      ..addAll(currentAndFutureQueue)
      ..addAll(messages);
    _queueIndex = _queue.indexWhere((message) => message.id == _currentlyPlayingMessage?.id);
    if (_queueIndex < 0) {
      _queueIndex = 0;
    }

    List<MediaItem> mediaItems = _queue.map((message) => message.toMediaItem()).toList();
    await updateQueue(queue: mediaItems, index: _queueIndex);
  }

  void removeFromQueue(int index) {
    Logger.logEvent(event: 'Removing item from queue at index $index');
    // can't remove currently playing message
    if (_queue != null && _queue[index]?.id == _currentlyPlayingMessage?.id) {
      return;
    } else {
      _audioHandler.removeQueueItemAt(index);
    }
  }

  void seekToSecond(double seconds) {
    int milliseconds = (seconds * 1000).round();
    _audioHandler.seekTo(position: Duration(milliseconds: milliseconds));
  }

  void seekForwardFifteenSeconds() {
    if (_currentlyPlayingMessage == null) {
      return;
    }
    _audioHandler.fastForward();
  }

  void seekBackwardFifteenSeconds() {
    if (_currentlyPlayingMessage == null) {
      return;
    }
    _audioHandler.rewind();
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

  void disposePlayer() async {
    _audioHandler.stop();
    _playerVisible = false;
    _queue = [];
    _queueIndex = null;
    notifyListeners();
    Logger.logEvent(event: 'Disposing of player; updating queue in database: $_queue');
    await db.reorderAllMessagesInPlaylist(Playlist(Constants.QUEUE_PLAYLIST_ID, 0, 'Queue', []), _queue);
    _prefs = await SharedPreferences.getInstance();
    _prefs.remove('mostRecentMessageId');
  }
}