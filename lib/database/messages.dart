import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<int> addToDB(Database db, Message msg) async {
  return await db.insert(messageTable, msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<void> batchAddToDB(Database db, List<Message> msgList) async {
  await db.transaction((txn) async {
    Batch batch = txn.batch();

    for (Message msg in msgList) {
      batch.insert(messageTable, msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
    }

    await batch.commit();
  });
}

Future<Message> queryOne(Database db, int id) async {
  List<Map<String,dynamic>> msgList = await db.query(messageTable, where: 'id = ?', whereArgs: [id]);
  
  if (msgList.length > 0) {
    return Message.fromMap(msgList.first);
  }
  return null;
}

Future<List<Message>> queryMultipleMessages({Database db, List<int> ids}) async {
  String idList = ids.join(',');
  var result = await db.rawQuery('''
    SELECT * FROM $messageTable
      WHERE id IN ($idList)
      ORDER BY instr('$idList', ',' || id || ',')
  ''');
  if (result.isNotEmpty) {
    return result.map((msgMap) => Message.fromMap(msgMap)).toList();
  }
  return [];
}

Future<int> update(Database db, Message msg) async {
  return await db.update(messageTable, msg.toMap(), where: 'id = ?', whereArgs: [msg.id]);
}

Future<int> delete(Database db, int id) async {
  return await db.delete(messageTable, where: 'id = ?', whereArgs: [id]);
}