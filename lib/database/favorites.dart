import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<List<int>> getFavoritesCount({Database db}) async {
  // returns [total, played]
  try {
    int total =  Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) from $messageTable WHERE isfavorite = 1'));
    int played =  Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) from $messageTable WHERE isfavorite = 1 AND isplayed = 1'));
    return [total, played];
  } catch (error) {
    print('Error getting favorites count: $error');
    return [0, 0];
  }
}

Future<List<Message>> queryFavorites({Database db, int start, int end, String orderBy, bool ascending = true}) async {
  String query = 'SELECT * from $messageTable WHERE isfavorite = 1';

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
    print('Error loading favorites: $error');
    return [];
  }
}