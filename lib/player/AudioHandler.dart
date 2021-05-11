import 'package:audio_service/audio_service.dart';
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
  List<MediaItem> _playableQueue(List<MediaItem> rawQueue) {
    // item.id corresponds to the filepath; if this is empty, it's not playable
    return _queue.where((item) => item.id != null && item.id.length > 0).toList();
  }
  removeQueueItemAt(int index) async {
    _queue.removeAt(index);
    broadcastQueueChanges();
  }
  addQueueItem(MediaItem item) async {
    if (_queue.indexWhere((i) => i.id == item.id) < 0) {
      _queue.add(item);
      broadcastQueueChanges();
    }
  }
  insertQueueItem(int index, MediaItem item) async {
    if (_queue.indexWhere((i) => i.id == item.id) < 0) {
      _queue.insert(index, item);
      broadcastQueueChanges();
    }
  }
  updateQueue(List<MediaItem> newQueue) async {
    _queue = newQueue;
    queue.add(_playableQueue(_queue));
    /*try {
      print('ready to set audio source');
      await setAudioSource();
      print('audio source has been set');
    } catch (error) {
      print('Error setting audio source: $error');
    }*/
    await broadcastQueueChanges();
  }
  Future<void> broadcastQueueChanges() async {
    queue.add(_playableQueue(_queue));
    int currentIndex = _player.currentIndex;
    Duration currentPosition = _player.position;
    try {
      await setAudioSource();
      seekTo(currentPosition, index: currentIndex);
    } catch (error) {
      print('Error setting audio source: $error');
    }
  }
  Future<void> setAudioSource() async {
    List<MediaItem> _validQueue = _playableQueue(_queue);
    await _player.setAudioSource(ConcatenatingAudioSource(
      children: _validQueue.map((item) => AudioSource.uri(Uri.parse('file://' + item.id))).toList(),
    ));
  }
  skipToPrevious() {
    return _player.seekToPrevious();
  }
  skipToNext() {
    return _player.seekToNext();
  }
  skipToQueueItem(int index) async  {
    seekTo(Duration(seconds: 0), index: index);
  }
  seekTo(Duration position, {int index}) {
    try {
      _player.seek(position, index: index);
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
        controls: [
          MediaControl.rewind,
          //MediaControl.skipToPrevious,
          _player.playing ? MediaControl.pause : MediaControl.play,
          //MediaControl.skipToNext,
          MediaControl.fastForward,
        ],
        androidCompactActionIndices: [0, 1, 2],
        systemActions: {
          MediaAction.seek,
          MediaAction.seekForward,
          MediaAction.seekBackward,
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