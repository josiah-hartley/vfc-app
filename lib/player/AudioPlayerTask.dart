import 'dart:async';

import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();
  StreamSubscription<PlaybackEvent> _eventSubscription;
  MediaItem _mediaItem = MediaItem(
    id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: Duration(milliseconds: 5739820),
  );
  List<MediaItem> _queue;

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    _queue = [_mediaItem];
    print('starting');
    print(params);
    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      _broadcastState();
    });
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(_mediaItem);
    });
    await _audioPlayer.setUrl('https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3');
    //_audioPlayer.play();

    AudioServiceBackground.setQueue(_queue);
    try {
      await _audioPlayer.setAudioSource(ConcatenatingAudioSource(
        children:
            _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
      ));
      // In this example, we automatically start playing on start.
      onPlay();
    } catch (e) {
      print("Error: $e");
      onStop();
    }
  }

  @override
  Future<void> onStop() async {
    await _audioPlayer.stop();
    await _broadcastState();
    await super.onStop();
  }

  @override
  Future<void> onPlay() async {
    //await _audioPlayer.setUrl('https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3');
    _audioPlayer.play();
  }

  @override
  Future<void> onPause() {
    _audioPlayer.pause();
  }

  /// Broadcasts the current state to all clients.
  Future<void> _broadcastState() async {
    await AudioServiceBackground.setState(
      controls: [
        MediaControl.skipToPrevious,
        if (_audioPlayer.playing) MediaControl.pause else MediaControl.play,
        MediaControl.stop,
        MediaControl.skipToNext,
      ],
      systemActions: [
        MediaAction.play,
        MediaAction.seekForward,
        MediaAction.seekBackward,
      ],
      //androidCompactActions: [0, 1, 3],
      processingState: _getProcessingState(),
      playing: _audioPlayer.playing,
      position: _audioPlayer.position,
      bufferedPosition: _audioPlayer.bufferedPosition,
      speed: _audioPlayer.speed,
    );
  }

  /// Maps just_audio's processing state into into audio_service's playing
  /// state. If we are in the middle of a skip, we use [_skipState] instead.
  AudioProcessingState _getProcessingState() {
    //if (_skipState != null) return _skipState;
    switch (_audioPlayer.processingState) {
      case ProcessingState.idle:
        return AudioProcessingState.stopped;
      case ProcessingState.loading:
        return AudioProcessingState.connecting;
      case ProcessingState.buffering:
        return AudioProcessingState.buffering;
      case ProcessingState.ready:
        return AudioProcessingState.ready;
      case ProcessingState.completed:
        return AudioProcessingState.completed;
      default:
        throw Exception("Invalid state: ${_audioPlayer.processingState}");
    }
  }
}