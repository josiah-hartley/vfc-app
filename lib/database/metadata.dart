import 'package:sqflite/sqlite_api.dart';

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