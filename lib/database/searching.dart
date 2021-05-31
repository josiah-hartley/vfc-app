import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/table_names.dart';

List<String> searchArguments(String searchTerm) {
  List<String> searchWords = searchTerm.split(' ');
  return (searchWords.map((w) => '%' + w + '%')).toList();
}

String queryWhere(String searchArg, List<String> comparisons) {
  if (searchArg == null || searchArg == '' || comparisons.length < 1) {
    return '';
  }

  String query = '${comparisons[0]} LIKE ?';
  for (int i = 1; i < comparisons.length; i++) {
    query += ' OR ${comparisons[i]} LIKE ?';
  }
  return query;
}

Future<List<Message>> queryArgList({Database db, String table, String searchTerm, List<String> comparisons, bool onlyUnplayed = false, int start, int end}) async {
  List<String> argList = searchArguments(searchTerm);

  if (argList.length < 1 || comparisons.length < 1) {
    return [];
  }
  
  String query = 'SELECT * from $table WHERE ('
    + queryWhere(argList[0], comparisons) + ')';
  List<String> args = List.filled(comparisons.length, argList[0], growable: true);
  
  for (int i = 1; i < argList.length; i++) {
    query += ' AND (' + queryWhere(argList[i], comparisons) + ')';
    args.addAll(List.filled(comparisons.length, argList[i]));
  }

  if (onlyUnplayed) {
     query += ' AND isplayed = 0';
  }

  if (start != null && end != null) {
    query += ' LIMIT ${(end - start).toString()} OFFSET ${start.toString()}';
  }
  
  try {
    var result = await db.rawQuery(query, args);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch (error) {
    print('Error searching SQLite database: $error');
    return [];
  }
}

Future<int> queryCountArgList ({Database db, String table, String searchTerm, List<String> comparisons, bool onlyUnplayed = false}) async {
  List<String> argList = searchArguments(searchTerm);

  if (argList.length < 1 || comparisons.length < 1) {
    return 0;
  }
  
  String query = 'SELECT COUNT(*) from $table WHERE ('
    + queryWhere(argList[0], comparisons) + ')';
  List<String> args = List.filled(comparisons.length, argList[0], growable: true);
  
  for (int i = 1; i < argList.length; i++) {
    query += ' AND (' + queryWhere(argList[i], comparisons) + ')';
    args.addAll(List.filled(comparisons.length, argList[i]));
  }

  if (onlyUnplayed) {
     query += ' AND isplayed = 0';
  }
  
  try {
    return Sqflite.firstIntValue(await db.rawQuery(query, args));
  } catch (error) {
    print('Error searching SQLite database: $error');
    return 0;
  }
}

Future<int> searchCountSpeakerTitle(Database db, String searchTerm) async {
  List<String> comparisons = ['speaker', 'title', 'taglist'];
  return queryCountArgList(
    db: db,
    table: messageTable,
    searchTerm: searchTerm,
    comparisons: comparisons,
  );
}

Future<List<Message>> searchBySpeakerOrTitle({Database db, String searchTerm, int start, int end}) async {
  List<String> comparisons = ['speaker', 'title', 'taglist'];
  return queryArgList(
    db: db,
    table: messageTable,
    searchTerm: searchTerm,
    comparisons: comparisons,
    start: start,
    end: end,
  );
}

Future<List<Message>> searchByColumns({Database db, String searchTerm, List<String> columns, bool onlyUnplayed, int start, int end}) async {
  return queryArgList(
    db: db,
    table: messageTable,
    searchTerm: searchTerm,
    comparisons: columns,
    onlyUnplayed: onlyUnplayed,
    start: start,
    end: end,
  );
}

/*Future<List<Message>> searchBySpeaker(String searchTerm, [int start, int end]) async {
  Database db = await instance.database;
  List<String> args = searchArguments(searchTerm);
  String query = 'SELECT * from $_messageTable WHERE ' + queryWhere('speaker', args);
  
  if (start != null && end != null) {
    query += ' LIMIT ${(end - start).toString()} OFFSET ${start.toString()}';
  }
  
  try {
    //var result = await db.query(_messageTable, where: "speaker LIKE ?", whereArgs: ['%' + searchTerm + '%']);
    var result = await db.rawQuery(query, args);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch (error) {
    print('Error searching SQLite database: $error');
    return [];
  }
}*/

/*Future<List<Message>> searchByTitle(String searchTerm, [int start, int end]) async {
  Database db = await instance.database;
  List<String> args = searchArguments(searchTerm);
  String query = 'SELECT * from $_messageTable WHERE ' + queryWhere('title', args);
  
  if (start != null && end != null) {
    query += ' LIMIT ${(end - start).toString()} OFFSET ${start.toString()}';
  }
  
  try {
    //var result = await db.query(_messageTable, where: "title LIKE ?", whereArgs: ['%' + searchTerm + '%']);
    var result = await db.rawQuery(query, args);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch (error) {
    print('Error searching SQLite database: $error');
    return [];
  }
}*/

/*Future<List<Message>> searchBySpeakerOrTitle(String searchTerm, [int start, int end]) async {
  Database db = await instance.database;
  List<String> args = searchArguments(searchTerm);
  String query = 'SELECT * from $_messageTable WHERE ' 
    + queryWhere('speaker', args) + ' OR '
    + queryWhere('title', args) + ' OR '
    + queryWhere('taglist', args);
  List<String> args3 = List.from(args)..addAll(args)..addAll(args);

  if (start != null && end != null) {
    query += ' LIMIT ${(end - start).toString()} OFFSET ${start.toString()}';
  }
  
  try {
    /*var result = await db.query(_messageTable, 
      where: "speaker LIKE ? OR title LIKE ? OR taglist LIKE ?", 
      whereArgs: ['%' + searchTerm + '%', '%' + searchTerm + '%', '%' + searchTerm + '%']);*/
    var result = await db.rawQuery(query, args3);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch (error) {
    print('Error searching SQLite database: $error');
    return [];
  }
}*/

/*Future<int> searchCountSpeakerTitle(String searchTerm) async {
  Database db = await instance.database;
  List<String> args = searchArguments(searchTerm);
  String query = 'SELECT COUNT(*) from $_messageTable WHERE ' 
    + queryWhere('speaker', args) + ' OR '
    + queryWhere('title', args) + ' OR '
    + queryWhere('taglist', args);
  List<String> args3 = List.from(args)..addAll(args)..addAll(args);
  
  try {
    return Sqflite.firstIntValue(await db.rawQuery(query, args3));
  } catch (error) {
    print('Error searching SQLite database: $error');
    return 0;
  }
}*/

/*Future<List<Message>> searchLimitOffset(String searchTerm, int start, int end) async {
  Database db = await instance.database;
  try {
    var result = await db.query(_messageTable, 
      where: "speaker LIKE ? OR title LIKE ? OR taglist LIKE ?", 
      whereArgs: ['%' + searchTerm + '%', '%' + searchTerm + '%', '%' + searchTerm + '%'],
      limit: end - start, offset: start);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  } catch (error) {
    print('Error searching SQLite database: $error');
    return [];
  }
}*/