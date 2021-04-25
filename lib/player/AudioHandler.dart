import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class VFCAudioHandler extends BaseAudioHandler {
  final _player = AudioPlayer();
  List<MediaItem> _queue = [];
  //bool playing = false;
  Stream<bool> playingStream;
  Stream<Duration> durationStream;
  //Stream<PlayerState> playerStateStream; // maybe don't need it
  //Stream<SequenceState> sequenceStateStream; // TODO: implement hasNext, hasPrevious
  
  play() {
    //playing = true;
    return _player.play();
  }
  pause() {
    //playing = false;
    return _player.pause();
  }
  updateQueue(List<MediaItem> newQueue) async {
    print('updating queue: $newQueue');
    _queue = newQueue;
    _player.setAudioSource(ConcatenatingAudioSource(
      children: _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
    ));
  }
  skipToQueueItem(int index) async  {
    print('skipping to $index');
    /*_player.setAudioSource(ConcatenatingAudioSource(
      children: _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
    ));*/
    seekTo(Duration(seconds: 0), index: index);
    //seekTo(Duration(seconds: 0), index: index);
    //_player.seek(Duration(seconds: 0), index: index);
    //_player.setUrl(_queue[index].id);
    print('DURATION IS ${_player.duration}');
  }
  seekTo(Duration position, {int index}) => _player.seek(position, index: index);
  stop() async {
    await _player.stop();
    //playing = false;
    await super.stop();
  }
  setSpeed(double speed) {
    return _player.setSpeed(speed);
  }

  VFCAudioHandler() {
    playingStream = _player.playingStream;
    durationStream = _player.durationStream;
    //playerStateStream = _player.playerStateStream;
    //sequenceStateStream = _player.sequenceStateStream;

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

    /*queue.listen((List<MediaItem> queue) { 
      print('listening: queue updated to $queue');
      _queue = queue;
      _player.setAudioSource(ConcatenatingAudioSource(
        children: _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
      ));
    });*/
  }
}