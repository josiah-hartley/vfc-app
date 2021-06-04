import 'package:audio_service/audio_service.dart';

class Message {
  int id;
  int created; // timestamp when message was added to cloud database
  String date; // year when message was given
  String language;
  String location;
  String speaker;
  String speakerurl;
  String taglist;
  String title;
  String url;
  num durationinseconds;
  int approximateminutes;
  num lastplayedposition;
  int lastplayeddate;
  int iscurrentlydownloading;
  int iscurrentlyplaying;
  int isdownloaded;
  int downloadedat;
  String filepath;
  int isfavorite;
  int isplayed;

  Message(
    this.id,
    this.created,
    this.date,
    this.language,
    this.location,
    this.speaker,
    this.speakerurl,
    this.taglist,
    this.title,
    this.url,
    this.durationinseconds,
    this.approximateminutes,
    this.lastplayedposition,
    this.lastplayeddate,
    this.iscurrentlydownloading,
    this.iscurrentlyplaying,
    this.isdownloaded,
    this.downloadedat,
    this.filepath,
    this.isfavorite,
    this.isplayed,
  );

  // message id's are unique; two messages are identical if they have the same id
  @override
  bool operator ==(o) => o is Message && o.id == id;
  @override
  int get hashCode => id.hashCode;

  Message.fromCloudMap(Map<String, dynamic> map) {
    // used when pulling message data from cloud database

    id = map['id'];
    created = map['created'];
    date = map['date'];
    language = map['language'];
    location = map['location'];
    speaker = map['speaker'];
    speakerurl = map['speakerUrl'];
    title = map['title'];
    url = map['url'];

    // convert List of tags into string
    taglist = '';
    if (map['tags'] != null && map['tags'].length > 0) {
      map['tags'].forEach((tag) => taglist += tag['display'] + ',');
    }
    
    if (taglist.length > 0) {
      taglist = taglist.substring(0, taglist.length - 1);
    }

    // get possibly null data
    durationinseconds = map['durationinseconds'];
    approximateminutes = map['approximateminutes'];
    lastplayedposition = map['lastplayedposition'] ?? 0.0;
    lastplayeddate = map['lastplayeddate'];
    iscurrentlydownloading = map['iscurrentlydownloading'] ?? 0;
    isdownloaded = map['isdownloaded'] ?? 0;
    downloadedat = map['downloadedat'] ?? 0;
    filepath = map['filepath'] ?? '';
    isfavorite = map['isfavorite'] ?? 0;
    isplayed = map['isplayed'] ?? 0;
  }

  Message.fromMap(Map<String, dynamic> map) {
    // used when pulling message data from local SQLite database

    id = map['id'];
    created = map['created'];
    date = map['date'];
    language = map['language'];
    location = map['location'];
    speaker = map['speaker'];
    speakerurl = map['speakerUrl'];
    title = map['title'];
    url = map['url'];
    taglist = map['taglist'];
    durationinseconds = map['durationinseconds'];
    approximateminutes = map['approximateminutes'];
    lastplayedposition = map['lastplayedposition'];
    lastplayeddate = map['lastplayeddate'];
    iscurrentlydownloading = map['iscurrentlydownloading'];
    isdownloaded = map['isdownloaded'];
    downloadedat = map['downloadedat'];
    filepath = map['filepath'];
    isfavorite = map['isfavorite'];
    isplayed = map['isplayed'];
  }

  Map<String, dynamic> toMap() {
    // used when adding message data to local SQLite database
    return {
      'id': id,
      'created': created,
      'date': date,
      'language': language,
      'location': location,
      'speaker': speaker,
      'speakerurl': speakerurl,
      'taglist': taglist,
      'title': title,
      'url': url,
      'durationinseconds': durationinseconds,
      'approximateminutes': approximateminutes,
      'lastplayedposition': lastplayedposition,
      'lastplayeddate': lastplayeddate,
      'isdownloaded': isdownloaded,
      'iscurrentlydownloading': iscurrentlydownloading,
      'downloadedat': downloadedat,
      'filepath': filepath,
      'isfavorite': isfavorite,
      'isplayed': isplayed
    };
  }

  MediaItem toMediaItem() {
    double seconds = durationinseconds ?? 0.0;
    int milliseconds = (seconds * 1000).round();
    Map<String, dynamic> _extras = toMap();
    return MediaItem(
      id: filepath,
      title: title,
      duration: Duration(milliseconds: milliseconds),
      artist: speaker,
      album: speaker,
      extras: _extras,
    );
  }

  String toString() {
    return '$title, by $speaker';
  }
}

Message messageFromMediaItem(MediaItem mediaItem) {
  if (mediaItem == null || mediaItem.extras == null) {
    return null;
  }
  Message result = Message.fromMap(mediaItem.extras);
  return result;
}