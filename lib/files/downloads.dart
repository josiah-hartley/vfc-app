import 'dart:async';
import 'dart:io';

//import 'package:audioplayers/audioplayers.dart';
import 'package:just_audio/just_audio.dart';
import 'package:path_provider/path_provider.dart';

import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/data_models/message_class.dart';

import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter/material.dart';

Future<void> deleteMessageFile(Message message) async {
  String dir = '';
  String filepath = '';

  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    filepath = '$dir/${message.id.toString()}.mp3';
  } catch (error) {
    print(error);
  }

  File f = File('$filepath');
  f.delete();
}

Future<Message> downloadMessageFile(Message message) async {
  String url = 'https://voicesforchrist.net/audio_messages/' + message.id.toString() + '?dl=true';
  String dir = '';
  String filepath = '';
  final db = MessageDB.instance;
  print('starting to download ${message.id}: ${message.title}');

  try {
    dir = (await getApplicationDocumentsDirectory()).path;
    filepath = '$dir/${message.id.toString()}.mp3';
  } 
  catch (error) {
    print(error);
  }

  try {
    message.iscurrentlydownloading = 1;
    await db.update(message);

    Message messageDownload = await _downloadAndSaveMp3(message, url, filepath);

    messageDownload.iscurrentlydownloading = 0;
    await db.update(messageDownload);
    print('finished downloading ${message.id}: ${message.title}');

    return messageDownload;
  } 
  catch (error) {
    print('Error in downloadMessageFile (download_mp3.dart): $error');

    message.iscurrentlydownloading = 0;
    await db.update(message);

    Fluttertoast.showToast(
      msg: "Error downloading: check connection",
      toastLength: Toast.LENGTH_LONG,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 3,
      backgroundColor: Colors.red[600],
      textColor: Colors.grey[50],
      fontSize: 16.0
    );

    throw Exception(error);
  }
}

Future<Message> _downloadAndSaveMp3(Message message, String url, String filepath) async {
  HttpClient client = new HttpClient();
  print('starting download');
  client.badCertificateCallback = ((X509Certificate cert, String host, int port) {
    final isValidHost = host == 'voicesforchrist.net';
    return isValidHost;
  });

  try {
    HttpClientRequest request = await client.getUrl(Uri.parse(url));
    HttpClientResponse response = await request.close();
    
    await response.pipe(new File('$filepath').openWrite());
    return await _updateMessageLocationAndDuration(message, filepath);
  } 
  catch (error) {
    print('Error downloading MP3 (_downloadAndSaveMp3 in download_mp3.dart): $error');
    throw Exception(error);
  }
}

Future<Message> _updateMessageLocationAndDuration(Message message, String filepath) async {
  try {
    final db = MessageDB.instance;
    Duration duration = await _getDuration(filepath);

    message.isdownloaded = 1;
    message.durationinseconds = duration?.inSeconds?.toDouble();
    message.filepath = filepath;
    await db.update(message);
    return message;
  } 
  catch (error) {
    print('Error getting duration in _updateMessageLocationAndDuration (download_mp3.dart): $error');
    throw Exception(error);
  }
}

Future<Duration> _getDuration(String filepath) async {
  //AudioPlayer player = AudioPlayer();
  //await player.setUrl(filepath, isLocal: true);
  AudioPlayer player = AudioPlayer();
  Duration duration = await player.setUrl(filepath);
  player.dispose();
  return duration;

  //int duration = await Future.delayed(Duration(seconds:1), () => player.getDuration());
  // TODO: use new audioplayer to get duration
  //int duration = 1000;
  //return Duration(milliseconds: duration);
}