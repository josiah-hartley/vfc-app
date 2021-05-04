import 'dart:io';
import 'package:dio/adapter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:dio/dio.dart';
import 'package:voices_for_christ/data_models/message_class.dart';

Future<Message> downloadMessageFile(Message message) async {
  Dio dio = Dio();
  // avoid certificate verification errors when accessing voicesforchrist.net
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
    client.badCertificateCallback = (X509Certificate certificate, String host, int port) {
      final isValidHost = host == 'voicesforchrist.net';
      return isValidHost;
    };
  };
  String url = 'https://voicesforchrist.net/audio_messages/' + message.id.toString() + '?dl=true';
  String dir = '';
  String filepath = '';
  print('starting to download ${message.id}: ${message.title}');

  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    filepath = '$dir/${message.id.toString()}.mp3';
  } 
  catch (error) {
    print(error);
    throw Exception(error);
  }

  try {
    //message.iscurrentlydownloading = 1;
    //await db.update(message);
    await dio.download(url, filepath, onReceiveProgress: (int current, int total) {
      print('downloaded $current of $total');
    });
    Duration duration = await _duration(filepath);
    message.iscurrentlydownloading = 0;
    message.isdownloaded = 1;
    message.filepath = filepath;
    message.durationinseconds = duration.inSeconds.toDouble();

    print('finished downloading ${message.id}: ${message.title}');
    return message;
  } 
  catch (error) {
    print('Error in downloadMessageFile (download_mp3.dart): $error');

    //message.iscurrentlydownloading = 0;
    //await db.update(message);

    throw Exception(error);
  }
}

Future<Duration> _duration(String filepath) async {
  try {
    AudioPlayer player = AudioPlayer();
    Duration duration = await player.setUrl(filepath);
    print('Duration is $duration');
    player.dispose();
    return duration;
  } catch(error) {
    print('Error getting duration of downloaded file: $error');
    return Duration(seconds: 0);
  }
}

Future<Message> deleteMessageFile(Message message) async {
  String dir = '';
  String filepath = '';

  try {
    print('DELETE: starting');
    dir = (await getApplicationDocumentsDirectory()).path;
    filepath = '$dir/${message.id.toString()}.mp3';
    File f = File('$filepath');
    if (await f.exists()) {
      f.delete();
    }
    print('DELETE: deleted file');

    print('DELETE: updating message info');
    message.isdownloaded = 0;
    message.filepath = '';
    print('DELETE: message info updated: ${message.isdownloaded} and ${message.filepath}');

    return message;
  } catch (error) {
    print('Error deleting file: $error');
    throw Exception(error);
  }
}