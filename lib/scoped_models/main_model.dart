import 'package:connectivity/connectivity.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/pause_reason.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
import 'package:voices_for_christ/scoped_models/downloads_model.dart';
import 'package:voices_for_christ/scoped_models/favorites_model.dart';
import 'package:voices_for_christ/scoped_models/player_model.dart';
import 'package:voices_for_christ/scoped_models/playlists_model.dart';
import 'package:voices_for_christ/scoped_models/recommendations_model.dart';
import 'package:voices_for_christ/scoped_models/settings_model.dart';

class MainModel extends Model 
with PlayerModel, 
FavoritesModel, 
DownloadsModel, 
PlaylistsModel, 
SettingsModel,
RecommendationsModel {
  ConnectivityResult _connection;

  ConnectivityResult get connection => _connection;

  void initialize() async {
    //DateTime start = DateTime.now();
    /*await initializePlayer(onChangedMessage: (Message message) {
      updateDownloadedMessage(message);
      updateFavoritedMessage(message);
      updateMessageInCurrentPlaylist(message);
    });*/
    DateTime a = DateTime.now();
    //print('initialized player: ${a.millisecondsSinceEpoch - start.millisecondsSinceEpoch} ms elapsed.');
    await loadPlaylistsMetadata();
    DateTime b = DateTime.now();
    print('loaded playlists metadata: ${b.millisecondsSinceEpoch - a.millisecondsSinceEpoch} ms elapsed.');
    await loadFavoritesFromDB();
    DateTime c = DateTime.now();
    print('loaded favorites from db: ${c.millisecondsSinceEpoch - b.millisecondsSinceEpoch} ms elapsed.');
    await loadDownloadedMessagesFromDB();
    DateTime d = DateTime.now();
    print('loaded downloaded messages from db: ${d.millisecondsSinceEpoch - c.millisecondsSinceEpoch} ms elapsed.');
    await loadDownloadQueueFromDB();
    DateTime e = DateTime.now();
    print('loaded download queue: ${e.millisecondsSinceEpoch - d.millisecondsSinceEpoch} ms elapsed.');
    await loadStorageUsage();
    DateTime f = DateTime.now();
    print('loaded storage usage: ${f.millisecondsSinceEpoch - e.millisecondsSinceEpoch} ms elapsed.');
    //await loadSettings();
    //DateTime g = DateTime.now();
    //print('loaded settings: ${g.millisecondsSinceEpoch - f.millisecondsSinceEpoch} ms elapsed.');
    //await loadRecommendations();
    DateTime h = DateTime.now();
    //print('loaded recommendations: ${h.millisecondsSinceEpoch - g.millisecondsSinceEpoch} ms elapsed.');
    await deletePlayedDownloads();
    DateTime i = DateTime.now();
    print('deleted played downloads: ${i.millisecondsSinceEpoch - h.millisecondsSinceEpoch} ms elapsed.');

    Connectivity().onConnectivityChanged.listen((ConnectivityResult connection) {
      _connection = connection;
      notifyListeners();
      print('connectivity changed: $connection');
      if (connection == ConnectivityResult.none) {
        pauseDownloadQueue(reason: PauseReason.noConnection);
      } else if (connection == ConnectivityResult.mobile && !downloadOverData) {
        pauseDownloadQueue(reason: PauseReason.connectionType);
      } else {
        // on wifi
        if (downloadsPaused) {
          unpauseDownloadQueue();
        }
      }
    });
  }

  void toggleDownloadOverData() {
    changeDownloadOverDataStoredSetting();
    if (!downloadOverData && _connection != ConnectivityResult.wifi) {
      pauseDownloadQueue(reason: PauseReason.connectionType);
    }
    if (downloadOverData && (_connection == ConnectivityResult.wifi || _connection == ConnectivityResult.mobile)) {
      unpauseDownloadQueue();
    }
  }

  Future<void> setMessagePlayed(Message message) async {
    message.isplayed = 1;
    //message.lastplayedposition = message.durationinseconds;
    await db.update(message);
    //await db.setPlayed(message);
    updateDownloadedMessage(message);
    updateFavoritedMessage(message);
    updateMessageInCurrentPlaylist(message);
    //await loadDownloads();
    //await loadFavorites();
    //notifyListeners();
  }

  Future<void> setMessageUnplayed(Message message) async {
    message.isplayed = 0;
    //message.lastplayedposition = 0.0;
    await db.update(message);
    //await db.setUnplayed(message);
    updateDownloadedMessage(message);
    updateFavoritedMessage(message);
    updateMessageInCurrentPlaylist(message);
    //await loadDownloads();
    //await loadFavorites();
    //notifyListeners();
  }

  Future<void> setMultiplePlayed(List<Message> messages, int value) async {
    for (int i = 0; i < messages.length; i++) {
      messages[i].isplayed = value;
      updateDownloadedMessage(messages[i]);
      updateFavoritedMessage(messages[i]);
    }
    await db.batchAddToDB(messages);
  }

  Future<void> toggleFavorite(Message message) async {
    await handleFavoriteToggling(message);
    bool subtract = message.isfavorite != 1;
    await updateRecommendations(messages: [message], subtract: subtract);
  }

  Future<void> queueDownloads(List<Message> messages, {bool showPopup = false}) async {
    if (showPopup && messages.length > 0) {
      String _messages = messages.length != 1 ? 'messages' : 'message';
      showToast('Added ${messages.length} $_messages to download queue');
    }
    await updateRecommendations(messages: messages);
    addMessagesToDownloadQueue(messages);
  }

  Future<void> deleteMessages(List<Message> messages) async {
    // can't delete currently playing message
    messages.removeWhere((m) => m?.id == currentlyPlayingMessage?.id);
    // can't delete any messages in the queue
    messages.removeWhere((m) => queue.indexWhere((message) => message.id == m.id) > -1);
    
    print('REMOVING DOWNLOADS: $messages');
    messages = await deleteMessageDownloads(messages);
    for (Message message in messages) {
      print('UPDATING $message');
      updateDownloadedMessage(message);
      updateFavoritedMessage(message);
      updateMessageInCurrentPlaylist(message);
    }
    /*for (int i = 0; i < messages.length; i++) {
      // if it's in the queue, remove it
      int index = queue.indexWhere((m) => m.id == messages[i].id);
      if (index > -1) {
        removeFromQueue(index);
      }
    }*/
  }

  Future<void> deletePlayedDownloads() async {
    if (removePlayedDownloads) {
      List<Message> downloads = await db.queryDownloads();
      List<Message> playedDownloads = downloads.where((m) => m.isplayed == 1).toList();
      print('REMOVING DOWNLOADS: $playedDownloads');
      await deleteMessages(playedDownloads);
    }
  }

  Future<List<Message>> recentMessages({int start, int end}) async {
    return await db.queryRecentlyPlayedMessages(start: start, end: end);
  }
}