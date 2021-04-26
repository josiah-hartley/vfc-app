import 'package:audio_service/audio_service.dart';
import 'package:voices_for_christ/data_models/message_class.dart';

class Playlist {
  int id;
  int created; // timestamp when playlist was created
  String title;
  List<Message> messages;

  Playlist(
    this.id,
    this.created,
    this.title,
    this.messages,
  );

  Playlist.fromMap(Map<String, dynamic> map) {
    // used when getting playlist data from database
    id = map['id'];
    created = map['created'];
    title = map['title'];
    messages = []; // fill in from separate database call
  }

  Map<String, dynamic> toMap() {
    // used when adding message data to local SQLite database
    return {
      'created': created,
      'title': title
    };
  }

  List<MediaItem> toMediaItemList() {
    return messages.map((msg) => msg.toMediaItem()).toList();
  }
}

/*Future<Playlist> playlistFromMediaItemList(List<MediaItem> itemList) async {
  List<Message> messages = [];
  for (int i = 0; i < itemList.length; i++) {
    Message message = await messageFromMediaItem(itemList[i]);
    messages.add(message);
  }
  return Playlist(-1, 0, 'Temp', messages);
}*/