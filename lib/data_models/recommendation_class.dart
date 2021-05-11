import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/reverse_speaker_name.dart';

class Recommendation {
  String label;
  String type;
  List<Message> messages;

  Recommendation({this.label, this.type, this.messages});

  Recommendation.fromMap(Map<String, dynamic> map) {
    label = map['label'];
    type = map['type'];
    messages = [];
  }

  String getHeader() {
    if (type == 'speaker') {
      String speakerName = speakerReversedName(label);
      return 'Messages by $speakerName';
    }
    if (type == 'featured') {
      return 'Featured Messages';
    }
    if (type == 'downloads') {
      return 'Recently Downloaded';
    }
    return 'Messages about $label';
  }

  String toString() {
    return getHeader();
  }
}