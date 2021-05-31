import 'dart:convert';

import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/database/table_names.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;

Future<void> saveEventLog({Database db, String type, String event}) async {
  try {
    int time = DateTime.now().millisecondsSinceEpoch;
    int id = await db.insert(loggingTable, {
      'timestamp': time,
      'type': type,
      'text': event,
    });
    if (id > Constants.LOGS_TO_KEEP_IN_DB) {
      await db.delete(loggingTable,
        where: 'id <= ?',
        whereArgs: [id - Constants.LOGS_TO_KEEP_IN_DB],
      );
    }
  } catch (error) {
    print('Error logging event: $error');
  }
}

Future<List<String>> getEventLogs({Database db, int limit}) async {
  try {
    List<Map<String, dynamic>> result;
    if (limit != null) {
      result = await db.query(loggingTable, orderBy: 'timestamp DESC', limit: limit);
    } else {
      result = await db.query(loggingTable, orderBy: 'timestamp DESC');
    }
    if (result == null || result.isEmpty) {
      return [];
    }
    return result.map((log) => jsonEncode(log)).toList();
  } catch (error) {
    print('Error getting event logs');
    return [];
  }
}