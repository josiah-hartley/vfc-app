import 'package:sqflite/sqlite_api.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future onCreateDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $messageTable (
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
        downloadedat INTEGER,
        filepath TEXT,
        isfavorite INTEGER,
        isplayed INTEGER
      )
    ''');

    await db.execute('''
      CREATE TABLE $playlistTable (
        id INTEGER PRIMARY KEY,
        created INTEGER,
        title TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE $messagesInPlaylist (
        messageid INTEGER NOT NULL REFERENCES $messageTable(id),
        playlistid INTEGER NOT NULL REFERENCES $playlistTable(id),
        messagerank INTEGER,
        PRIMARY KEY(messageid, playlistid)
      )
    ''');

    await db.execute('''
      CREATE TABLE $downloads (
        messageid INTEGER NOT NULL,
        initiated INTEGER,
        PRIMARY KEY(messageid)
      )
    ''');

    await db.execute('''
      CREATE TABLE $metaTable (
        id INTEGER,
        label TEXT,
        value INTEGER,
        PRIMARY KEY(id)
      )
    ''');

    Map<String, dynamic> savedMap = {
      'id': 0,
      'created': DateTime.now().millisecondsSinceEpoch,
      'title': 'Saved for Later'
    };

    await db.insert(playlistTable, savedMap, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(metaTable, {'id': 0, 'label': 'cloudLastCheckedDate', 'value': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
    await db.insert(metaTable, {'id': 1, 'label': 'storageused', 'value': 0}, conflictAlgorithm: ConflictAlgorithm.replace);
  }