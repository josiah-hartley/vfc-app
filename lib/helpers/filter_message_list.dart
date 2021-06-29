import 'package:voices_for_christ/data_models/message_class.dart';

List<Message> filterMessageList({List<Message> messages, String searchTerm}) {
  if (searchTerm == null || searchTerm.length < 1) {
    return messages;
  }
  List<String> searchWords = searchTerm.split(' ');
  return messages.where((message) {
    for (int i = 0; i < searchWords.length; i++) {
      String word = searchWords[i];
      if (!message.title.toLowerCase().contains(word.toLowerCase()) && 
          !message.speaker.toLowerCase().contains(word.toLowerCase())) {
        // filter to messages that contain all search words
        // somewhere in title or speaker name
        return false;
      }
    }
    return true;
  }).toList();
}