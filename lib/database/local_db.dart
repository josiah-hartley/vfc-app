import 'dart:async';
import 'dart:io';
import 'package:flutter/services.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/data_models/recommendation_class.dart';
import 'package:voices_for_christ/database/on_create.dart';
import 'package:voices_for_christ/database/table_names.dart';
import 'package:voices_for_christ/database/metadata.dart' as meta;
import 'package:voices_for_christ/database/messages.dart' as messages;
import 'package:voices_for_christ/database/favorites.dart' as favorites;
import 'package:voices_for_christ/database/downloads.dart' as downloadsMethods;
import 'package:voices_for_christ/database/searching.dart' as search;
import 'package:voices_for_christ/database/playlists.dart' as playlists;
import 'package:voices_for_christ/database/recommendations.dart' as recommendations;
import 'package:voices_for_christ/database/logs.dart' as logs;

class MessageDB {
  //static final _databaseVersion = 1;

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
    String path = join(dbDir, databaseName);

    // first time: copy initial database from assets
    bool exists = await databaseExists(path);
    if (!exists) {
      // make sure the parent directory exists
      try {
        await Directory(dirname(path)).create(recursive: true);
      } catch (_) {}
        
      // copy from asset
      ByteData data = await rootBundle.load(join("assets", "initial_message_database.db"));
      List<int> bytes =
      data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      
      // write and flush the bytes written
      await File(path).writeAsBytes(bytes, flush: true);
    }

    return await openDatabase(path);
  }

  // SQL create
  

  /* Database Helper Methods */

  // METADATA TABLE
  Future<int> getLastUpdatedDate() async {
    Database db = await instance.database;
    return await meta.getLastUpdatedDate(db);
  }

  Future setLastUpdatedDate(int date) async {
    Database db = await instance.database;
    await meta.setLastUpdatedDate(db, date);
  }

  Future<int> getStorageUsed() async {
    Database db = await instance.database;
    return await meta.getStorageUsed(db);
  }

  Future<void> updateStorageUsed({int bytes, bool add = true}) async {
    Database db = await instance.database;
    await meta.updateStorageUsed(
      db: db,
      bytes: bytes,
      add: add,
    );
  }

  // MESSAGES TABLE
  Future<int> addToDB(Message message) async {
    Database db = await instance.database;
    return await messages.addToDB(db, message);
  }

  Future batchAddToDB(List<Message> messageList) async {
    Database db = await instance.database;
    await messages.batchAddToDB(db, messageList);
  }

  Future<Message> queryOne(int id) async {
    Database db = await instance.database;
    return await messages.queryOne(db, id);
  }

  Future<List<Message>> queryMultipleMessages(List<int> ids) async {
    Database db = await instance.database;
    return await messages.queryMultipleMessages(db: db, ids: ids);
  }

  Future<List<Message>> queryRecentlyPlayedMessages({int start, int end}) async {
    Database db = await instance.database;
    return await messages.queryRecentlyPlayedMessages(db: db, start: start, end: end);
  }

  Future<int> getTotalTimeListened() async {
    Database db = await instance.database;
    return await messages.getTotalTimeListened(db: db);
  }

  Future<int> update(Message msg) async {
    Database db = await instance.database;
    return await messages.update(db, msg);
  }

  Future<int> delete(int id) async {
    Database db = await instance.database;
    return await messages.delete(db, id);
  }

  Future<int> toggleFavorite(Message msg) async {
    if (msg.isfavorite == 1) {
      msg.isfavorite = 0;
    } else {
      msg.isfavorite = 1;
    }
    
    return await update(msg);
  }

  /*Future<int> setPlayed(Message msg) async {
    msg.lastplayedposition = msg.durationinseconds;
    msg.isplayed = 1;
    return await update(msg);
  }

  Future<int> setUnplayed(Message msg) async {
    msg.lastplayedposition = 0.0;
    msg.isplayed = 0;
    return await update(msg);
  }*/

  // FAVORITES
  /*Future<int> getFavoritesCount() async {
    Database db = await instance.database;
    return await favorites.getFavoritesCount(db: db);
  }*/

  Future<List<Message>> queryFavorites({int start, int end, String orderBy, bool ascending = true}) async {
    Database db = await instance.database;
    return await favorites.queryFavorites(
      db: db,
      start: start,
      end: end,
      orderBy: orderBy,
      ascending: ascending,
    );
  }

  // DOWNLOADS
  /*Future<int> getDownloadsCount() async {
    Database db = await instance.database;
    return await downloadsMethods.getDownloadsCount(db: db);
  }*/

  Future<List<Message>> queryDownloads({int start, int end, String orderBy, bool ascending = true}) async {
    Database db = await instance.database;
    return await downloadsMethods.queryDownloads(
      db: db,
      start: start,
      end: end,
      orderBy: orderBy,
      ascending: ascending,
    );
  }

  Future<List<Message>> getDownloadQueueFromDB() async {
    Database db = await instance.database;
    return await downloadsMethods.getDownloadQueueFromDB(db);
  }

  Future<void> addMessagesToDownloadQueueDB(List<Message> messages) async {
    Database db = await instance.database;
    await downloadsMethods.addMessagesToDownloadQueueDB(db, messages);
  }

  Future<void> removeMessagesFromDownloadQueueDB(List<Message> messages) async {
    Database db = await instance.database;
    await downloadsMethods.removeMessagesFromDownloadQueueDB(db, messages);
  }

  // SEARCHING
  Future<int> searchCountSpeakerTitle(String searchTerm) async {
    Database db = await instance.database;
    return await search.searchCountSpeakerTitle(db, searchTerm);
  }

  Future<List<Message>> searchBySpeakerOrTitle(String searchTerm, [int start, int end]) async {
    Database db = await instance.database;
    return await search.searchBySpeakerOrTitle(db, searchTerm);
  }

  Future<List<Message>> searchByColumns({String searchTerm, List<String> columns, int start, int end}) async {
    Database db = await instance.database;
    return await search.searchByColumns(
      db: db, 
      searchTerm: searchTerm,
      columns: columns,
      start: start,
      end: end
    );
  }

  // PLAYLISTS
  Future<int> newPlaylist(String title) async {
    Database db = await instance.database;
    return await playlists.newPlaylist(db, title);
  }

  Future<List<Playlist>> getAllPlaylistsMetadata() async {
    Database db = await instance.database;
    return await playlists.getAllPlaylistsMetadata(db);
  }

  Future<List<Message>> getMessagesOnPlaylist(Playlist playlist) async {
    Database db = await instance.database;
    return await playlists.getMessagesOnPlaylist(db, playlist);
  }

  Future<List<Playlist>> getPlaylistsContainingMessage(Message message) async {
    Database db = await instance.database;
    return playlists.getPlaylistsContainingMessage(db, message);
  }

  Future<int> editPlaylistTitle(Playlist playlist, String title) async {
    Database db = await instance.database;
    return await playlists.editPlaylistTitle(db, playlist, title);
  }

  Future<void> addMessagesToPlaylist({List<Message> messages, Playlist playlist}) async {
    Database db = await instance.database;
    await playlists.addMessagesToPlaylist(db: db, messages: messages, playlist: playlist);
  }

  Future<int> removeMessageFromPlaylist(Message msg, Playlist playlist) async {
    Database db = await instance.database;
    return await playlists.removeMessageFromPlaylist(db, msg, playlist);
  }

  Future<int> reorderMessageInPlaylist(Playlist playlist, Message message, int oldIndex, int newIndex) async {
    Database db = await instance.database;
    return await playlists.reorderMessageInPlaylist(
      db: db,
      playlist: playlist,
      message: message,
      oldIndex: oldIndex,
      newIndex: newIndex,
    );
  }

  Future<void> reorderAllMessagesInPlaylist(Playlist playlist, List<Message> messages) async {
    Database db = await instance.database;
    await playlists.reorderAllMessagesInPlaylist(db, playlist, messages);
  }

  Future<void> updatePlaylistsContainingMessage(Message message, List<Playlist> updatedPlaylists) async {
    Database db = await instance.database;
    await playlists.updatePlaylistsContainingMessage(db, message, updatedPlaylists);
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    Database db = await instance.database;
    await playlists.deletePlaylist(db, playlist);
  }

  // RECOMMENDATIONS
  Future<void> updateRecommendationsBasedOnMessages({List<Message> messages, bool subtract = false}) async {
    Database db = await instance.database;
    await recommendations.updateRecommendationsBasedOnMessages(db: db, messages: messages, subtract: subtract);
  }

  Future<List<Recommendation>> getRecommendations({int recommendationCount, int messageCount}) async {
    Database db = await instance.database;
    List<Recommendation> _recs =  await recommendations.getRecommendations(db: db, limit: recommendationCount);
    for (int i = 0; i < _recs.length; i++) {
      _recs[i].messages = await searchByColumns(
        searchTerm: _recs[i].label,
        columns: _recs[i].type == 'speaker' ? ['speaker'] : ['taglist'],
        start: 0,
        end: messageCount,
      );
    }
    return _recs;
  }

  Future<List<Message>> getMoreMessagesForRecommendation({Recommendation recommendation, int messageCount}) async {
    return await searchByColumns(
      searchTerm: recommendation.label,
      columns: recommendation.type == 'speaker' ? ['speaker'] : ['taglist'],
      start: recommendation.messages.length,
      end: recommendation.messages.length + messageCount,
    );
  }

  // LOGGING
  Future<void> saveEventLog({String type, String event}) async {
    Database db = await instance.database;
    await logs.saveEventLog(
      db: db,
      type: type,
      event: event,
    );
  }

  Future<List<String>> getEventLogs() async {
    Database db = await instance.database;
    return await logs.getEventLogs(db: db);
  }

  // RESETTING DATABASE
  Future resetDB() async {
    Database db = await instance.database;
    await db.execute('DROP TABLE IF EXISTS $messageTable');
    await db.execute('DROP TABLE IF EXISTS $speakerTable');
    await db.execute('DROP TABLE IF EXISTS $playlistTable');
    await db.execute('DROP TABLE IF EXISTS $messagesInPlaylist');
    await db.execute('DROP TABLE IF EXISTS $downloads');
    await db.execute('DROP TABLE IF EXISTS $metaTable');
    await onCreateDB(db, 1);

    // reset date of last update from cloud database
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setInt('cloudLastCheckedDate', 0);
  }
}