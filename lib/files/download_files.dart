import 'dart:io';
import 'package:dio/dio.dart';
import 'package:dio/adapter.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:voices_for_christ/data_models/download_class.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
//import 'package:voices_for_christ/helpers/toasts.dart';

Future<Message> downloadMessageFile({Download task, Function onReceiveProgress}) async {
  if (task == null || task.message == null) {
    return null;
  }
  Dio dio = Dio();
  // avoid certificate verification errors when accessing voicesforchrist.net
  (dio.httpClientAdapter as DefaultHttpClientAdapter).onHttpClientCreate = (HttpClient client) {
    client.badCertificateCallback = (X509Certificate certificate, String host, int port) {
      final isValidHost = host == 'voicesforchrist.net';
      return isValidHost;
    };
  };
  String url = 'https://voicesforchrist.net/audio_messages/' + task.message.id.toString() + '?dl=true';
  String dir = '';
  String filepath = '';
  print('starting to download ${task.message.id}: ${task.message.title}');

  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    filepath = '$dir/${task.message.id.toString()}.mp3';
  } 
  catch (error) {
    print(error);
    throw Exception(error);
  }

  try {
    await dio.download(url, filepath, cancelToken: task.cancelToken, onReceiveProgress: onReceiveProgress);
    Duration duration = await _duration(filepath);
    task.message.iscurrentlydownloading = 0;
    task.message.isdownloaded = 1;
    task.message.filepath = filepath;
    task.message.durationinseconds = duration.inSeconds.toDouble();

    print('finished downloading ${task.message.id}: ${task.message.title}');
    return task.message;
  } 
  catch (error) {
    if (error.toString().indexOf('DioErrorType.cancel') > -1) {
      task.message.iscurrentlydownloading = 0;
      task.message.isdownloaded = 0;
      task.message.filepath = '';
      //showToast('Canceled download: ${task.message.title}');
      return task.message;
    }
    print('Error in downloadMessageFile (downloads.dart) for ${task.message.title}: $error');
    throw Exception(error);
  }
}

Future<Duration> _duration(String filepath) async {
  try {
    AudioPlayer player = AudioPlayer();
    Duration duration = await player.setFilePath(filepath);
    player.dispose();
    return duration;
  } catch(error) {
    print('Error getting duration of downloaded file: $error');
    return Duration(seconds: 0);
  }
}