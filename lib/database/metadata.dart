import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<int> getLastUpdatedDate(Database db) async {
  List<Map<String,dynamic>> result = await db.query('meta', where: 'label = ?', whereArgs: ['cloudLastCheckedDate']);

  if (result.length > 0) {
    return result.first['value'];
  }
  return null;
}

Future<void> setLastUpdatedDate(Database db, int date) async {
  Map<String,dynamic> row = {'id': 0, 'label': 'cloudLastCheckedDate', 'value': date};
  await db.insert('meta', row, conflictAlgorithm: ConflictAlgorithm.replace);
}

Future<int> getStorageUsed(Database db) async {
  try {
    List<Map<String,dynamic>> result = await db.query('$metaTable', where: 'label = ?', whereArgs: ['storageused']);
    print('finding cloudlastcheckeddate: $result');
    if (result.length > 0) {
      return result.first['value'];
    }
    return 0;
  } catch(error) {
    print('Error getting storage used: $error');
    return 0;
  }
}

Future<void> updateStorageUsed({Database db, int bytes, bool add = true}) async {
  String snippet = add ? 'value + ?' : 'value - ?';
  try {
    await db.rawUpdate('''
      UPDATE $metaTable
      SET value = $snippet
      WHERE label = 'storageused'
    ''', [bytes]);
  } catch(error) {
    print('Error adding to storage usage: $error');
  }
}