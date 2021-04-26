import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class VFCAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  List<MediaItem> _queue = [];
  bool hasNext;
  bool hasPrevious;
  Stream<bool> playingStream;
  Stream<Duration> durationStream;
  
  play() {
    return _player.play();
  }
  pause() {
    return _player.pause();
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
    queue.add(_queue);
    await _player.setAudioSource(ConcatenatingAudioSource(
      children: _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
    ));
    //await broadcastQueueChanges();
  }
  Future<void> broadcastQueueChanges() async {
    queue.add(_queue);
    int currentIndex = _player.currentIndex;
    Duration currentPosition = _player.position;
    await _player.setAudioSource(ConcatenatingAudioSource(
      children: _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
    ));
    seekTo(currentPosition, index: currentIndex);
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
  seekTo(Duration position, {int index}) => _player.seek(position, index: index);
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
      if (index != null) {
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