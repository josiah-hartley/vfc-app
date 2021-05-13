import 'dart:io';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';

// TODO: update cloud API to match message class
Future getMessageDataFromCloud({Function onCompleted}) async {
  // see when database was last updated
  final db = MessageDB.instance;
  int lastUpdated = await db.getLastUpdatedDate() ?? 0;
  String url = '${Constants.CLOUD_DATABASE_BASE_URL}?time=$lastUpdated';

  // get all messages since last update
  try {
    final response = await http.get(Uri.parse(url));

    if (response.statusCode == 200) {
      Map<String, dynamic> msgMap = json.decode(response.body);

      // Add data in batches
      List<Message> msgList = [];

      for (var m in msgMap.entries) {
        m.value['id'] = int.parse(m.key);
        Message msg = Message.fromCloudMap(m.value);

        msgList.add(msg);
      }
      await db.batchAddToDB(msgList);

      // save current time as last updated time
      db.setLastUpdatedDate(DateTime.now().millisecondsSinceEpoch);
      
      if (onCompleted != null) {
        onCompleted();
      }
    } else {
      throw HttpException('Server error: failed to load messages from Firestore');
    }
  } catch (error) {
    throw error;
  }
}