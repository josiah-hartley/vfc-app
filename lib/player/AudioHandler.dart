import 'dart:io';

import 'package:audio_service/audio_service.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';

class VFCAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  List<MediaItem> _queue = [];
  //bool hasNext;
  //bool hasPrevious;
  Stream<bool> playingStream;
  Stream<Duration> durationStream;
  
  play() {
    return _player.play();
  }
  pause() {
    return _player.pause();
  }
  Future<List<MediaItem>> _playableQueue(List<MediaItem> rawQueue) async{
    if (rawQueue == null) {
      return [];
    }
    // item.id corresponds to the filepath; if this is empty or the file doesn't exist, it's not playable
    List<MediaItem> result = [];
    for (int i = 0; i < rawQueue.length; i++) {
      MediaItem item = rawQueue[i];
      if (item.id != null && item.id.length > 0) {
        File f = File('${item.id}');
        if (await f.exists()) {
          result.add(item);
        }
      }
    }
    return result;
    //return rawQueue.where((item) => item.id != null && item.id.length > 0).toList();
  }
  removeQueueItemAt(int index) async {
    int indexToSeekTo;
    if (index < _player.currentIndex) {
      // removing from the past queue
      indexToSeekTo = _player.currentIndex - 1;
    }
    _queue.removeAt(index);
    broadcastQueueChanges(positionToSeekTo: _player.position, indexToSeekTo: indexToSeekTo);
  }
  addQueueItem(MediaItem item) async {
    // an item can only appear in the queue once
    if (_queue.indexWhere((i) => i.id == item.id) < 0) {
      _queue.add(item);
      broadcastQueueChanges();
    }
  }
  /*insertQueueItem(int index, MediaItem item) async {
    if (_queue.indexWhere((i) => i.id == item.id) < 0) {
      _queue.insert(index, item);
      broadcastQueueChanges();
    }
  }*/
  updateQueue(List<MediaItem> newQueue, {int index}) async {
    _queue = newQueue;
    // an item can only appear in the queue once
    // only the first occurrence will remain
    Set<String> queueIds = newQueue.map((i) => i.id).toSet();
    _queue.retainWhere((item) => queueIds.remove(item.id));
    _queue = await _playableQueue(_queue);
    MediaItem itemToSeekTo = index == null || index < 0 || index >= newQueue.length ? null : newQueue[index];
    int indexInPlayableQueue = 0;
    if (itemToSeekTo != null) {
      indexInPlayableQueue = _queue.indexWhere((item) => item?.id == newQueue[index]?.id);
      if (indexInPlayableQueue < 0) {
        indexInPlayableQueue = 0;
      }
    }
    //queue.add(await _playableQueue(_queue));
    /*try {
      print('ready to set audio source');
      await setAudioSource();
      print('audio source has been set');
    } catch (error) {
      print('Error setting audio source: $error');
    }*/
    await broadcastQueueChanges(indexToSeekTo: indexInPlayableQueue);
  }
  Future<void> broadcastQueueChanges({Duration positionToSeekTo, int indexToSeekTo}) async {
    _queue = await _playableQueue(_queue);
    queue.add(_queue);
    print('PLAYER INDEX IS ${_player.currentIndex}');
    int currentIndex = _player.currentIndex ?? 0;
    if (currentIndex < 0 || currentIndex >= _queue.length) {
      currentIndex = 0;
    }
    Duration currentPosition = _player.position ?? Duration(seconds: 0);
    try {
      await setAudioSource();
      print('INDEX TO SEEK TO IS $indexToSeekTo; currentIndex is $currentIndex');
      if (indexToSeekTo == null) {
        print('SEEKING TO $currentPosition at index $currentIndex in queue ${_queue.map((item) => item.title).toList()}');
        seekTo(position: currentPosition, index: currentIndex);
      } else {
        seekTo(position: positionToSeekTo ?? Duration(seconds: 0), index: indexToSeekTo);
      }
    } catch (error) {
      print('Error setting audio source: $error');
    }
  }
  Future<void> setAudioSource() async {
    List<MediaItem> _validQueue = await _playableQueue(_queue);
    try {
      if (_validQueue.length > 0) {
        await _player.setAudioSource(ConcatenatingAudioSource(
          children: _validQueue.map((item) => AudioSource.uri(Uri.parse('file://' + item.id))).toList(),
        ));
      }
    } on PlatformException {
      print('Error setting audio source');
    }
  }
  skipToPrevious() {
    return _player.seekToPrevious();
  }
  skipToNext() {
    print('SKIPPTING TO NEXT: INDEX IS ${_player.currentIndex}');
    return _player.seekToNext();
  }
  fastForward() async {
    if (_player.duration.inSeconds - _player.position.inSeconds > 15) {
      seekTo(position: Duration(seconds: _player.position.inSeconds + 15));
    } else {
      seekTo(position: Duration(seconds: _player.duration.inSeconds - 1));
    }
  }
  rewind() async {
    if (_player.position.inSeconds >= 15) {
      seekTo(position: Duration(seconds: _player.position.inSeconds - 15));
    } else {
      seekTo(position: Duration(seconds: 0));
    }
  }
  seek(Duration position) async {
    seekTo(position: position);
  }
  skipToQueueItem(int index) async  {
    seekTo(position: Duration(seconds: 0), index: index);
  }
  seekTo({Duration position, int index}) {
    try {
      if (position?.inSeconds != null && position.inSeconds >= 0 && position.inSeconds <= (_player.duration?.inSeconds ?? 0)) {
        _player.seek(position, index: index);
      }
    } catch (error) {
      print('Error seeking to position $position: $error');
    }
  }
  stop() async {
    await _player.stop();
    await super.stop();
  }
  setSpeed(double speed) {
    return _player.setSpeed(speed);
  }

  VFCAudioHandler() {
    playingStream = _player.playingStream;
    durationStream = _player.durationStream;

    

    // Broadcast which item is currently playing
    _player.currentIndexStream.listen((index) {
      if (index != null && _queue.length > index) {
        //mediaItem.add(queue.valueWrapper.value[index]);
        mediaItem.add(_queue[index]);
      }
    });
    // Broadcast the current playback state and what controls should currently
    // be visible in the media notification
    _player.playbackEventStream.listen((event) async {
      int index = _player.currentIndex;
      if (index != null && _queue.length > index) {
        mediaItem.add(_queue[index]);
      }

      playbackState.add(playbackState.valueWrapper.value.copyWith(
        controls: mediaControls(_player),
        androidCompactActionIndices: [0, 1, 2],
        systemActions: {
          MediaAction.seek,
          //MediaAction.seekForward,
          //MediaAction.seekBackward,
        },
        processingState: {
          ProcessingState.idle: AudioProcessingState.idle,
          ProcessingState.loading: AudioProcessingState.loading,
          ProcessingState.buffering: AudioProcessingState.buffering,
          ProcessingState.ready: AudioProcessingState.ready,
          ProcessingState.completed: AudioProcessingState.completed,
        }[_player.processingState],
        playing: _player.playing,
        updatePosition: _player.position,
        bufferedPosition: _player.bufferedPosition,
        speed: _player.speed,
      ));
    });
  }
}

List<MediaControl> mediaControls(AudioPlayer player) {
  List<MediaControl> _controls = [
    MediaControl(
      androidIcon: 'drawable/ic_action_seek_backward',
      label: 'Seek Backward',
      action: MediaAction.rewind,
    ),
    player.playing
      ? MediaControl(
        androidIcon: 'drawable/ic_action_pause',
        label: 'Pause',
        action: MediaAction.pause,
      )
      : MediaControl(
        androidIcon: 'drawable/ic_action_play',
        label: 'Play',
        action: MediaAction.play,
      ),
    //_player.playing ? MediaControl.pause : MediaControl.play,
    MediaControl(
      androidIcon: 'drawable/ic_action_seek_forward',
      label: 'Seek Forward',
      action: MediaAction.fastForward,
    ),
    //MediaControl.skipToNext,
  ];

  if (player.hasNext) {
    _controls.add(MediaControl(
      androidIcon: 'drawable/ic_action_skip_forward',
      label: 'Skip to Next',
      action: MediaAction.skipToNext,
    ));
  }

  return _controls;
}