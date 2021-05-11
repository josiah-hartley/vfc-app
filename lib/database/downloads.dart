import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<List<Message>> queryDownloads({Database db, int start, int end, String orderBy, bool ascending = true}) async {
  String query = 'SELECT * from $messageTable WHERE isdownloaded = 1';

  if (orderBy != null) {
    query += ' ORDER BY ' + orderBy;
    ascending ? query += ' ASC' : query += ' DESC';
  }

  if (start != null && end != null) {
    query += ' LIMIT ${(end - start).toString()} OFFSET ${start.toString()}';
  }
  
  try {
    var result = await db.rawQuery(query);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch (error) {
    print('Error loading downloads: $error');
    return [];
  }
}

Future<List<Message>> getDownloadQueueFromDB(Database db) async {
  try {
    var result = await db.rawQuery('''
      SELECT * FROM $messageTable
      INNER JOIN $downloads 
      ON $messageTable.id = $downloads.messageid 
      ORDER BY $downloads.initiated
    ''');

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch(error) {
    print('Error getting messages in download queue: $error');
    return [];
  }
}

Future<void> addMessagesToDownloadQueueDB(Database db, List<Message> messages) async {
  int time = DateTime.now().millisecondsSinceEpoch;
  try {
    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (Message message in messages) {
        batch.insert(downloads, {
          'messageid': message.id,
          'initiated': time,
        }, conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit();
    });
  } catch(error) {
    print('Error adding messages to download queue in database');
  }
}

Future<void> removeMessagesFromDownloadQueueDB(Database db, List<Message> messages) async {
  try {
    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (Message message in messages) {
        batch.delete(downloads, where: "messageid = ?", whereArgs: [message.id]);
      }

      await batch.commit();
    });
  } catch(error) {
    print('Error removing messages from download queue in database');
  }
}