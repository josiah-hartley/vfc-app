import 'package:voices_for_christ/database/local_db.dart';

Future<void> logEvent({String type='action', String event}) async {
  final db = MessageDB.instance;
  await db.saveEventLog(type: type, event: event);
}

Future<List<String>> getEventLogs({int limit}) async {
  final db = MessageDB.instance;
  return await db.getEventLogs(limit: limit);
}