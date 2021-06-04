import 'dart:io';
import 'package:audio_service/audio_service.dart';

Future<List<MediaItem>> playableQueue(List<MediaItem> rawQueue) async {
  if (rawQueue == null) {
    return [];
  }
  // item.id corresponds to the filepath; if this is empty or the file doesn't exist, it's not playable
  List<MediaItem> result = [];
  for (int i = 0; i < rawQueue.length; i++) {
    MediaItem item = rawQueue[i];
    if (await mediaItemIsPlayable(item)) {
      result.add(item);
    }
  }
  return result;
}

Future<bool> mediaItemIsPlayable(MediaItem item) async {
  if (item.id != null && item.id.length > 0) {
    File f = File('${item.id}');
    if (await f.exists()) {
      return true;
    } else {
      return false;
    }
  } else {
    return false;
  }
}