import 'dart:async';
import 'package:audio_service/audio_service.dart';
import 'package:just_audio/just_audio.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';

class AudioPlayerTask extends BackgroundAudioTask {
  final _audioPlayer = AudioPlayer();
  StreamSubscription<PlaybackEvent> _eventSubscription;
  AudioProcessingState _skipState;
  /*MediaItem _mediaItem = MediaItem(
    id: "https://s3.amazonaws.com/scifri-episodes/scifri20181123-episode.mp3",
    album: "Science Friday",
    title: "A Salute To Head-Scratching Science",
    artist: "Science Friday and WNYC Studios",
    duration: Duration(milliseconds: 5739820),
  );*/
  bool _playing;
  List<MediaItem> _queue = <MediaItem>[];
  int _queueIndex = -1;
  //int get index => 0;//_audioPlayer.currentIndex;
  MediaItem get _mediaItem => _queueIndex == null ? null : _queue[_queueIndex];

  @override
  Future<void> onStart(Map<String, dynamic> params) async {
    _queue.clear();
    /*List<Message> messages = params['messageQueue'];
    for (int i = 0; i < messages.length; i++) {
      MediaItem messageMediaItem = messages[i].toMediaItem();
      _queue.add(messageMediaItem);
    }*/
    MediaItem _msg = MediaItem.fromJson(params['message']);
    _queue.add(_msg);
    //_queue = params['queue'];
    /*final db = MessageDB.instance;
    Message _defaultMessage = await db.queryOne(56823);
    _queue = [
      _defaultMessage.toMediaItem(),
    ];
    
    //mediaItem = _queue[params['index']];
    //print('starting');
    //print(params);
    print(_queue);*/

    // broadcast media item changes
    _audioPlayer.currentIndexStream.listen((index) {
      if (index != null) AudioServiceBackground.setMediaItem(_queue[index]);
    });
    // propagate all events from the audio player to AudioService clients.
    _eventSubscription = _audioPlayer.playbackEventStream.listen((event) {
      _broadcastState();
    });
    // special processing for state transitions.
    _audioPlayer.processingStateStream.listen((state) {
      switch (state) {
        case ProcessingState.completed:
          break;
        case ProcessingState.ready:
          // if we just came from skipping between tracks, clear the skip
          // state now that we're ready to play.
          _skipState = null;
          break;
        default:
          break;
      }
    });
    
    //await _audioPlayer.setUrl('https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3');
    //_audioPlayer.play();

    AudioServiceBackground.setQueue(_queue);
    onSkipToNext();
    /*try {
      await _audioPlayer.setAudioSource(ConcatenatingAudioSource(
        children:
          _queue.map((item) => AudioSource.uri(Uri.parse(item.id))).toList(),
      ));
      _audioPlayer.seek(params['position'] ?? Duration(seconds: 0), index: params['index'] ?? 0);
      // In this example, we automatically start playing on start.
      //onPlay();
    } catch (e) {
      print("Error setting audio source for _audioPlayer: $e");
      onStop();
    }*/
  }

  @override
  Future<void> onStop() async {
    try {
      await _audioPlayer.stop();
      await _broadcastState();
      _playing = false;
    } catch(e) {
      print('Error stopping _audioPlayer: $e');
    }
    await super.onStop();
  }

  @override
  Future<void> onPlay() async {
    //await _audioPlayer.setUrl('https://s3.amazonaws.com/scifri-segments/scifri201711241.mp3');
    _audioPlayer.play();
    _playing = true;
  }

  @override
  Future<void> onPause() {
    _audioPlayer.pause();
    _playing = false;
  }

  @override
  Future<void> onSkipToNext() {
    skip(1);
  }

  void skip(int offset) async {
    int next = _queueIndex + offset;
    if (next < 0 || next >= _queue.length) {
      return;
    }
    if (_playing == null) {
      _playing = true;
    } else if (_playing) {
      await _audioPlayer.stop();
    }
    _queueIndex = next;
    /*_skipState = offset > 0
        ? AudioProcessingState.skippingToNext
        : AudioProcessingState.skippingToPrevious;*/
    AudioServiceBackground.setMediaItem(_mediaItem);
    await _audioPlayer.setUrl(_mediaItem.id);
    print(_mediaItem.id);
    _skipState = null;
    if (_playing) {
      onPlay();
    } else {
      _broadcastState();
    }
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
    if (_skipState != null) return _skipState;
    switch (_audioPlayer.processingState) {
      case ProcessingState.idle:
        //return AudioProcessingState.stopped;
      case ProcessingState.loading:
        //return AudioProcessingState.connecting;
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