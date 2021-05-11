import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<void> deleteAll(Database db) async {
  // reset date of last update from cloud database
  SharedPreferences prefs = await SharedPreferences.getInstance();
  prefs.setInt('cloudLastCheckedDate', 0);

  await db.execute('DELETE FROM $messageTable');
}

Future<int> queryRowCount(Database db) async {
  return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $messageTable'));
}