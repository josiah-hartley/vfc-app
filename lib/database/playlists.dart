import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<int> newPlaylist(Database db, String title) async {
  Map<String, dynamic> playlistMap = {
    'title': title,
    'created': DateTime.now().millisecondsSinceEpoch
  };
  try {
    int result = await db.insert(playlistTable, playlistMap, conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  } catch(error) {
    print('Error creating new playlist: $error');
    return null;
  }
}

Future<List<Playlist>> getAllPlaylistsMetadata(Database db) async {
  try {
    // MAGIC NUMBER: the queue is a hidden playlist with id 0
    var result = await db.query(playlistTable, where: 'id != 0');
    // TODO: set up queue as playlist; save on changes, get on app reload, etc.

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

Future<List<Message>> getMessagesOnPlaylist(Database db, Playlist playlist) async {
  int id = playlist.id;

  try {
    var result = await db.rawQuery('''
      SELECT * FROM $messagesInPlaylist 
      INNER JOIN $messageTable 
      ON $messageTable.id = $messagesInPlaylist.messageid 
      WHERE $messagesInPlaylist.playlistid = $id
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

Future<List<Playlist>> getPlaylistsContainingMessage(Database db, Message message) async {
  int id = message.id;

  try {
    var result = await db.rawQuery('''
      SELECT * from $messagesInPlaylist
      INNER JOIN $playlistTable
      ON $playlistTable.id = $messagesInPlaylist.playlistid
      WHERE $messagesInPlaylist.messageid = $id
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

Future<Map<int, int>> getMaxMessageRanks(Database db, List<Playlist> playlists) async {
  try {
    Map<int, int> result = await db.transaction((txn) async {
      Map<int, int> maxRanks = {};
      //Batch batch = txn.batch();
      for (Playlist playlist in playlists) {
        maxRanks[playlist.id] = Sqflite.firstIntValue(
          await txn.rawQuery('''
            SELECT MAX(messagerank) FROM $messagesInPlaylist 
            WHERE $messagesInPlaylist.playlistid = ${playlist.id}
          ''')
        ) ?? 0;
      }
      return maxRanks;
    });
    return result;
  } catch(error) {
    print('Error getting max message ranks: $error');
    return {};
  }
}

Future<int> editPlaylistTitle(Database db, Playlist playlist, String title) async {
  try {
    int result = await db.update(playlistTable, {'title': title}, where: 'id = ?', whereArgs: [playlist.id]);
    return result;
  } catch(error) {
    print('Error editing playlist title');
    return null;
  }
}

Future<int> addMessageToPlaylist(Database db, Message msg, Playlist playlist) async {
  int id = playlist.id;

  try {
    int highestRank = Sqflite.firstIntValue(
      await db.rawQuery('''
        SELECT MAX(messagerank) FROM $messagesInPlaylist 
        WHERE $messagesInPlaylist.playlistid = $id
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

    int result = await db.insert(messagesInPlaylist, messageInPlaylist, conflictAlgorithm: ConflictAlgorithm.replace);
    return result;
  } catch(error) {
    print('Error adding message to playlist: $error');
    return null;
  } 
}

Future<int> removeMessageFromPlaylist(Database db, Message msg, Playlist playlist) async {
  try {
    var result = await db.rawQuery('''
      SELECT messagerank from $messagesInPlaylist
      WHERE (playlistid = ? AND messageid = ?)
    ''', [playlist.id, msg.id]);

    List<Map<String, dynamic>> messageInPlaylist = result.toList();

    await db.delete(messagesInPlaylist, where: 'messageid = ? AND playlistid = ?', whereArgs: [msg.id, playlist.id]);

    return await db.rawUpdate('''
      UPDATE $messagesInPlaylist 
      SET messagerank = messagerank - 1 
      WHERE (playlistid = ? AND messagerank > ?)
    ''', [playlist.id, messageInPlaylist[0]['messagerank']]);
  } catch(error) {
    print('Error removing message from playlist');
    return null;
  }
}

Future<int> reorderMessageInPlaylist({Database db, Playlist playlist, Message message, int oldIndex, int newIndex}) async {
  int playlistId = playlist.id;
  int messageId = message.id;

  if (oldIndex == newIndex) {
    return 0;
  }

  String query = 'UPDATE $messagesInPlaylist';
  
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
      UPDATE $messagesInPlaylist 
      SET messagerank = ?
      WHERE (playlistid = ? AND messageid = ?)
    ''', [newIndex, playlistId, messageId]);
  } catch (error) {
    print(error);
    return 0;
  }
}

Future<void> reorderAllMessagesInPlaylist(Database db, Playlist playlist, List<Message> messages) async {
  int playlistId = playlist.id;
  int rank = 0;

  try {
    await db.rawDelete('''
      DELETE FROM $messagesInPlaylist
      WHERE playlistid = ?
    ''', [playlistId]);

    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (Message message in messages) {
        batch.rawInsert('''
          INSERT INTO $messagesInPlaylist(messageid, playlistid, messagerank)
          VALUES(?, ?, ?)
        ''', [message.id, playlistId, rank]);
        rank += 1;
      }

      await batch.commit();
      return;
    });
  } catch (error) {
    print(error);
    return;
  }
}

Future<void> updatePlaylistsContainingMessage(Database db, Message message, List<Playlist> updatedPlaylists) async {
  try {
    List<Playlist> allPlaylists = await getAllPlaylistsMetadata(db);
    List<Playlist> previousPlaylists = await getPlaylistsContainingMessage(db, message);
    Map<int, int> maxMessageRanks = await getMaxMessageRanks(db, updatedPlaylists);

    await db.transaction((txn) async {
      Batch batch = txn.batch();
      //batch.delete(_messagesInPlaylist, where: 'messageid = ?', whereArgs: [message.id]);

      for (Playlist playlist in allPlaylists) {
        bool shouldBeSelected = updatedPlaylists.indexWhere((p) => p.id == playlist.id) > -1;
        bool wasOriginallySelected = previousPlaylists.indexWhere((p) => p.id == playlist.id) > -1;
        if (shouldBeSelected && !wasOriginallySelected) {
          // add
          batch.insert(messagesInPlaylist, {
            'messageid': message.id,
            'playlistid': playlist.id,
            'messagerank': maxMessageRanks == null ? 1 : maxMessageRanks[playlist.id] + 1,
          }, conflictAlgorithm: ConflictAlgorithm.replace);
        } 
        if (!shouldBeSelected && wasOriginallySelected) {
          // remove
          batch.delete(messagesInPlaylist, where: 'messageid = ?', whereArgs: [message.id]);
        }
      }
      await batch.commit();
    });
  } catch(error) {
    print('Error updating playlists containing message: $error');
  }
}

Future<void> deletePlaylist(Database db, Playlist playlist) async {
  try {
    await db.delete(playlistTable, where: 'id = ?', whereArgs: [playlist.id]);
    await db.delete(messagesInPlaylist, where: 'playlistid = ?', whereArgs: [playlist.id]);
  } catch(error) {
    print('Error deleting playlist: $error');
  }
}