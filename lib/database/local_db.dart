import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';

class MessageDB {
  static final _databaseName = 'message_database.db';
  //static final _databaseVersion = 1;
  static final _messageTable = 'messages';
  static final _speakerTable = 'speakers';
  static final _playlistTable = 'playlists';
  static final _messagesInPlaylist = 'mpjunction';

  // make it a singleton class
  MessageDB._privateConstructor();
  static final MessageDB instance = MessageDB._privateConstructor();

  // only have a single app-wide reference to the database
  static Database _database;
  Future<Database> get database async {
    // return open database or open it
    if (_database != null) return _database;

    _database = await _initDatabase();
    return _database;
  }

  // open database (or create if it doesn't exist)
  _initDatabase() async {
    String dbDir = await getDatabasesPath();
    String path = join(dbDir, _databaseName);

    //  NEW STUFF: TRYING TO START WITH INITIAL DATA

    // first time: copy initial database from assets
    bool exists = await databaseExists(path);
    if (!exists) {
      //print('Copying initial data from file.');
      //int startTime = DateTime.now().millisecondsSinceEpoch;
      // Make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
        
      // Copy from asset
      ByteData data = await rootBundle.load(join("assets", "initial_message_database.db"));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // Write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
      //int endTime = DateTime.now().millisecondsSinceEpoch;
      //print('done; took ' + (endTime - startTime).toString() + ' ms');
    } else {
      //print('Opening existing database');
    }

    return await openDatabase(path);

    // END OF NEW STUFF

    /*return await openDatabase(path,
      version: _databaseVersion,
      onCreate: _onCreate);*/
  }

  // SQL create
  Future _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $_messageTable (
        id INTEGER PRIMARY KEY,
        created INTEGER,
        date TEXT,
        language TEXT,
        location TEXT,
        speaker TEXT,
        speakerurl TEXT,
        taglist TEXT,
        title TEXT,
        url TEXT,
        durationinseconds REAL,
        lastplayedposition REAL,
        isdownloaded INTEGER,
        iscurrentlyplaying INTEGER,
        filepath TEXT,
        isfavorite INTEGER,
        isplayed INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $_playlistTable (
        id INTEGER PRIMARY KEY,
        created INTEGER,
        title TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $_messagesInPlaylist (
        messageid INTEGER NOT NULL REFERENCES $_messageTable(id),
        playlistid INTEGER NOT NULL REFERENCES $_playlistTable(id),
        messagerank INTEGER,
        PRIMARY KEY(messageid, playlistid)
      )
    ''');

    Map<String, dynamic> savedMap = {
      'id': 0,
      'created': DateTime.now().millisecondsSinceEpoch,
      'title': 'Saved for Later'
    };

    await db.insert(_playlistTable, savedMap, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  /* Database Helper Methods */

  // LAST UPDATED METADATA

  Future<int> getLastUpdatedDate() async {
    Database db = await instance.database;
    List<Map<String,dynamic>> result = await db.query('meta', where: 'label = ?', whereArgs: ['cloudLastCheckedDate']);
  
    if (result.length > 0) {
      return result.first['value'];
    }
    return null;
  }

  Future setLastUpdatedDate(int date) async {
    Database db = await instance.database;
    Map<String,dynamic> row = {'id': 0, 'label': 'cloudLastCheckedDate', 'value': date};
    await db.insert('meta', row, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  // MESSAGES

  Future<int> addToDB(Message msg) async {
    Database db = await MessageDB.instance.database;
    return await db.insert(_messageTable, msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
  }

  Future batchAddToDB(List<Message> msgList) async {
    Database db = await MessageDB.instance.database;

    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (Message msg in msgList) {
        batch.insert(_messageTable, msg.toMap(), conflictAlgorithm: ConflictAlgorithm.replace);
      }

      await batch.commit();
    });
  }

  Future<Message> queryOne(int id) async {
    Database db = await MessageDB.instance.database;
    List<Map<String,dynamic>> msgList = await db.query(_messageTable, where: 'id = ?', whereArgs: [id]);
    
    if (msgList.length > 0) {
      return Message.fromMap(msgList.first);
    }
    return null;
  }

  Future<int> toggleFavorite(Message msg) async {
    if (msg.isfavorite == 1) {
      msg.isfavorite = 0;
    } else {
      msg.isfavorite = 1;
    }
    
    return await update(msg);
  }

  Future<int> setPlayed(Message msg) async {
    msg.lastplayedposition = msg.durationinseconds;
    msg.isplayed = 1;

    return await update(msg);
  }

  Future<int> setUnplayed(Message msg) async {
    msg.lastplayedposition = 0.0;
    msg.isplayed = 0;

    return await update(msg);
  }

  Future<int> update(Message msg) async {
    Database db = await MessageDB.instance.database;
    return await db.update(_messageTable, msg.toMap(), where: 'id = ?', whereArgs: [msg.id]);
  }

  Future<int> delete(int id) async {
    Database db = await MessageDB.instance.database;
    return await db.delete(_messageTable, where: 'id = ?', whereArgs: [id]);
  }

  Future<List<Message>> queryAll() async {
    Database db = await instance.database;
    var result = await db.query(_messageTable);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  }

  Future<List<Message>> queryRange(int start, int end) async {
    Database db = await instance.database;
    var result = await db.query(_messageTable, limit: end - start, offset: start);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  }

  Future<List<Message>> queryFavorites() async {
    Database db = await instance.database;
    var result = await db.query(_messageTable, where: 'isfavorite = ?', whereArgs: [1]);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  }

  Future<List<Message>> queryDownloads() async {
    Database db = await instance.database;
    var result = await db.query(_messageTable, where: 'isdownloaded = ?', whereArgs: [1]);

    if (result.isNotEmpty) {
      List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
      return messages;
    }
    return [];
  }

  List<String> searchArguments(String searchTerm) {
    List<String> searchWords = searchTerm.split(' ');
    return (searchWords.map((w) => '%' + w + '%')).toList();
  }

  /*String queryWhere(String comparison, List<String> searchArgs) {
    if (searchArgs.length < 1) {
      return '';
    }
    String query = '$comparison LIKE ?';
    for (int i = 1; i < searchArgs.length; i++) {
      query += ' OR $comparison LIKE ?';
    }
    return query;
  }*/

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

  Future<List<Message>> queryArgList(String table, String searchTerm, List<String> comparisons, [int start, int end]) async {
    Database db = await instance.database;
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

    if (start != null && end != null) {
      query += ' LIMIT ${(end - start).toString()} OFFSET ${start.toString()}';
    }
    
    //try {
      var result = await db.rawQuery(query, args);

      if (result.isNotEmpty) {
        List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
        return messages;
      }
      return [];
    //} catch (error) {
      //print('Error searching SQLite database: $error');
      //return [];
    //}
  }

  Future<int> queryCountArgList (String table, String searchTerm, List<String> comparisons) async {
    Database db = await instance.database;
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
    
    try {
      return Sqflite.firstIntValue(await db.rawQuery(query, args));
    } catch (error) {
      print('Error searching SQLite database: $error');
      return 0;
    }
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

  Future<int> searchCountSpeakerTitle(String searchTerm) async {
    /*Database db = await instance.database;
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
    }*/

    List<String> comparisons = ['speaker', 'title', 'taglist'];
    return queryCountArgList(_messageTable, searchTerm, comparisons);
  }

  Future<List<Message>> searchBySpeakerOrTitle(String searchTerm, [int start, int end]) async {
    //Database db = await instance.database;
    //List<String> args = searchArguments(searchTerm);
    /*String query = 'SELECT * from $_messageTable WHERE ' 
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
    }*/
    
    List<String> comparisons = ['speaker', 'title', 'taglist'];
    return queryArgList(_messageTable, searchTerm, comparisons, start, end);
  }

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

  Future deleteAll() async {
    // reset date of last update from cloud database
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('cloudLastCheckedDate', 0);

    Database db = await instance.database;
    await db.execute('DELETE FROM $_messageTable');
  }

  Future<int> queryRowCount() async {
    Database db = await instance.database;
    return Sqflite.firstIntValue(await db.rawQuery('SELECT COUNT(*) FROM $_messageTable'));
  }

  // PLAYLISTS

  Future<int> newPlaylist(String title) async {
    Database db = await MessageDB.instance.database;
    Map<String, dynamic> playlistMap = {
      'title': title,
      'created': DateTime.now().millisecondsSinceEpoch
    };
    try {
      int result = await db.insert(_playlistTable, playlistMap, conflictAlgorithm: ConflictAlgorithm.replace);
      return result;
    } catch(error) {
      print('Error creating new playlist: $error');
      return null;
    }
  }

  Future<int> editPlaylistTitle(Playlist playlist, String title) async {
    Database db = await MessageDB.instance.database;
    /*return await db.rawUpdate('''
      UPDATE $_playlistTable
      SET title = ?
      WHERE id = ?
    ''', [title, playlist.id]);*/
    try {
      int result = await db.update(_playlistTable, {'title': title}, where: 'id = ?', whereArgs: [playlist.id]);
      return result;
    } catch(error) {
      print('Error editing playlist title');
      return null;
    }
  }

  Future<List<Playlist>> getAllPlaylistsMetadata() async {
    Database db = await instance.database;
    
    try {
      var result = await db.query(_playlistTable);

      if (result.isNotEmpty) {
        List<Playlist> playlists = result.map((pMap) => Playlist.fromMap(pMap)).toList();
            
        return playlists;
      }
      return [];
    } catch (error) {
      print(error);
      return [];
    }
  }

  Future<List<Playlist>> getAllPlaylists() async {
    Database db = await instance.database;
    
    try {
      var result = await db.query(_playlistTable);

      if (result.isNotEmpty) {
        List<Playlist> playlists = result.map((pMap) => Playlist.fromMap(pMap)).toList();
        
        for (int i = 0; i < playlists.length; i++) {
          playlists[i].messages = await getMessagesOnPlaylist(playlists[i]);
        }

        /*playlists.forEach((playlist) async {
          playlist.messages = await getMessagesOnPlaylist(playlist);
        });*/
        
        return playlists;
      }
      return [];
    } catch (error) {
      print(error);
      return [];
    }
  }

  Future<int> addMessageToPlaylist(Message msg, Playlist playlist) async {
    Database db = await instance.database;
    int id = playlist.id;

    try {
      int highestRank = Sqflite.firstIntValue(
        await db.rawQuery('''
          SELECT MAX(messagerank) FROM $_messagesInPlaylist 
          WHERE $_messagesInPlaylist.playlistid = $id
        ''')
      );
      if (highestRank == null) {
        highestRank = 0;
      }

      Map<String,dynamic> messageInPlaylist = {
        'messageid': msg.id,
        'playlistid': playlist.id,
        'messagerank': highestRank + 1
      };

      int result = await db.insert(_messagesInPlaylist, messageInPlaylist, conflictAlgorithm: ConflictAlgorithm.replace);
      return result;
    } catch(error) {
      print('Error adding message to playlist: $error');
      return null;
    }
    
  }

  Future<int> removeMessageFromPlaylist(Message msg, Playlist playlist) async {
    Database db = await instance.database;

    try {
      var result = await db.rawQuery('''
        SELECT messagerank from $_messagesInPlaylist
        WHERE (playlistid = ? AND messageid = ?)
      ''', [playlist.id, msg.id]);

      List<Map<String, dynamic>> messageInPlaylist = result.toList();

      await db.delete(_messagesInPlaylist, where: 'messageid = ? AND playlistid = ?', whereArgs: [msg.id, playlist.id]);

      return await db.rawUpdate('''
        UPDATE $_messagesInPlaylist 
        SET messagerank = messagerank - 1 
        WHERE (playlistid = ? AND messagerank > ?)
      ''', [playlist.id, messageInPlaylist[0]['messagerank']]);
    } catch(error) {
      print('Error removing message from playlist');
      return null;
    }
  }

  Future<int> reorderMessageInPlaylist(Playlist playlist, Message message, int oldIndex, int newIndex) async {
    Database db = await instance.database;
    int playlistId = playlist.id;
    int messageId = message.id;

    if (oldIndex == newIndex) {
      return 0;
    }

    String query = 'UPDATE $_messagesInPlaylist';
    
    if (oldIndex > newIndex) {
      // moving up the list
      query += ' SET messagerank = messagerank + 1 WHERE (playlistid = ? AND messagerank >= ? AND messagerank < ?)';
    } else {
      // moving down the list
      query += ' SET messagerank = messagerank - 1 WHERE (playlistid = ? AND messagerank <= ? AND messagerank > ?)';
    }

    try {
      await db.rawUpdate(query, [playlistId, newIndex, oldIndex]);

      return await db.rawUpdate('''
        UPDATE $_messagesInPlaylist 
        SET messagerank = ?
        WHERE (playlistid = ? AND messageid = ?)
      ''', [newIndex, playlistId, messageId]);
    } catch (error) {
      print(error);
      return 0;
    }
  }

  Future<int> reorderAllMessagesInPlaylist(Playlist playlist, List<Message> messages) async {
    Database db = await instance.database;
    int playlistId = playlist.id;
    int rank = 0;

    try {
      await db.rawDelete('''
        DELETE FROM $_messagesInPlaylist
        WHERE playlistid = ?
      ''', [playlistId]);

      for (Message message in messages) {
        await db.rawInsert('''
          INSERT INTO $_messagesInPlaylist(messageid, playlistid, messagerank)
          VALUES(?, ?, ?)
        ''', [message.id, playlistId, rank]);
        /*await db.rawUpdate('''
          UPDATE $_messagesInPlaylist
          SET messagerank = ?
          WHERE (playlistid = ? AND messageid = ?)
        ''', [rank, playlistId, message.id]);*/
        rank += 1;
      }
      return 1;
    } catch (error) {
      print(error);
      return 0;
    }
  }

  Future deletePlaylist(Playlist playlist) async {
    Database db = await instance.database;
    try {
      await db.delete(_playlistTable, where: 'id = ?', whereArgs: [playlist.id]);
      await db.delete(_messagesInPlaylist, where: 'playlistid = ?', whereArgs: [playlist.id]);
    } catch(error) {
      print('Error deleting playlist: $error');
    }
  }

  Future<List<Message>> getMessagesOnPlaylist(Playlist playlist) async {
    Database db = await instance.database;
    int id = playlist.id;

    try {
      var result = await db.rawQuery('''
        SELECT * FROM $_messagesInPlaylist 
        INNER JOIN $_messageTable 
        ON $_messageTable.id = $_messagesInPlaylist.messageid 
        WHERE $_messagesInPlaylist.playlistid = $id
        ORDER BY messagerank
      ''');

      if (result.isNotEmpty) {
        List<Message> messages = result.map((msgMap) => Message.fromMap(msgMap)).toList();
        return messages;
      }
      return [];
    } catch(error) {
      print('Error getting messages on playlist: $error');
      return [];
    }
  }

  Future<List<Playlist>> getPlaylistsContainingMessage(Message message) async {
    Database db = await instance.database;
    int id = message.id;

    try {
      var result = await db.rawQuery('''
        SELECT * from $_messagesInPlaylist
        INNER JOIN $_playlistTable
        ON $_playlistTable.id = $_messagesInPlaylist.playlistid
        WHERE $_messagesInPlaylist.messageid = $id
      ''');

      if (result.isNotEmpty) {
        List<Playlist> playlists = result.map((pMap) => Playlist.fromMap(pMap)).toList();
        return playlists;
      }
      return [];
    } catch(error) {
      print('Error getting playlists containing message: $error');
      return [];
    }
  }

  Future<Map<int, int>> getMaxMessageRanks(List<Playlist> playlists) async {
    Database db = await MessageDB.instance.database;

    try {
      Map<int, int> result = await db.transaction((txn) async {
        Map<int, int> maxRanks = {};
        //Batch batch = txn.batch();
        for (Playlist playlist in playlists) {
          maxRanks[playlist.id] = Sqflite.firstIntValue(
            await txn.rawQuery('''
              SELECT MAX(messagerank) FROM $_messagesInPlaylist 
              WHERE $_messagesInPlaylist.playlistid = ${playlist.id}
            ''')
          );
        }
        return maxRanks;
      });
      return result;
    } catch(error) {
      print('Error getting max message ranks: $error');
      return {};
    }
  }

  Future updatePlaylistsContainingMessage(Message message, List<Playlist> updatedPlaylists) async {
    Database db = await MessageDB.instance.database;

    try {
      List<Playlist> allPlaylists = await getAllPlaylistsMetadata();
      List<Playlist> previousPlaylists = await getPlaylistsContainingMessage(message);
      Map<int, int> maxMessageRanks = await getMaxMessageRanks(updatedPlaylists);

      await db.transaction((txn) async {
        Batch batch = txn.batch();
        //batch.delete(_messagesInPlaylist, where: 'messageid = ?', whereArgs: [message.id]);

        for (Playlist playlist in allPlaylists) {
          bool shouldBeSelected = updatedPlaylists.indexWhere((p) => p.id == playlist.id) > -1;
          bool wasOriginallySelected = previousPlaylists.indexWhere((p) => p.id == playlist.id) > -1;
          if (shouldBeSelected && !wasOriginallySelected) {
            // add
            batch.insert(_messagesInPlaylist, {
              'messageid': message.id,
              'playlistid': playlist.id,
              'messagerank': maxMessageRanks[playlist.id] + 1 ?? 1,
            }, conflictAlgorithm: ConflictAlgorithm.replace);
          } 
          if (!shouldBeSelected && wasOriginallySelected) {
            // remove
            batch.delete(_messagesInPlaylist, where: 'messageid = ?', whereArgs: [message.id]);
          }
        }
        await batch.commit();
      });
    } catch(error) {
      print('Error updating playlists containing message: $error');
    }
  }

  // RESETTING DATABASE

  Future resetDB() async {
    Database db = await instance.database;
    await db.execute('DROP TABLE IF EXISTS $_messageTable');
    await db.execute('DROP TABLE IF EXISTS $_speakerTable');
    await db.execute('DROP TABLE IF EXISTS $_playlistTable');
    await db.execute('DROP TABLE IF EXISTS $_messagesInPlaylist');
    await _onCreate(db, 1);

    // reset date of last update from cloud database
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('cloudLastCheckedDate', 0);
  }
}