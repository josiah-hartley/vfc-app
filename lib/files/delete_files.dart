import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:voices_for_christ/data_models/message_class.dart';

Future<int> deleteMessageFiles(List<Message> messages) async {
  // returns the cumulative size of deleted files, in bytes
  String dir = '';
  String filepath = '';
  int bytes = 0;

  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    for (int i = 0; i < messages.length; i++) {
      filepath = '$dir/${messages[i].id.toString()}.mp3';
      File f = File('$filepath');
      if (await f.exists()) {
        bytes += await f.length();
        f.delete();
      }
    }
    return bytes;
  } catch (error) {
    print('Error deleting file: $error');
    throw Exception(error);
  }
}