import 'package:connectivity_plus/connectivity_plus.dart';
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
import 'package:voices_for_christ/helpers/logger.dart' as Logger;

class MainModel extends Model 
with PlayerModel, 
FavoritesModel, 
DownloadsModel, 
PlaylistsModel, 
SettingsModel,
RecommendationsModel {
  ConnectivityResult _connection;

  ConnectivityResult get connection => _connection;

  Future<void> initialize(Function updateLoadingMessage) async {
    /*await initializePlayer(onChangedMessage: (Message message) {
      updateDownloadedMessage(message);
      updateFavoritedMessage(message);
      updateMessageInCurrentPlaylist(message);
    });*/
    updateLoadingMessage('Loading playlists...');
    await loadPlaylistsMetadata();
    updateLoadingMessage('Loading favorites...');
    await loadFavoritesFromDB();
    updateLoadingMessage('Loading downloads...');
    await loadDownloadedMessagesFromDB();
    await loadDownloadQueueFromDB(showPopup: false);
    await loadStorageUsage();
    updateLoadingMessage('Removing played downloads...');
    await deletePlayedDownloads();
    await Logger.logEvent(event: 'Initializing MainModel: finished loading from db');

    Connectivity().onConnectivityChanged.listen((ConnectivityResult connection) {
      _connection = connection;
      notifyListeners();
      Logger.logEvent(event: 'Connectivity changed: $connection');
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
    await Logger.logEvent(event: 'Initializing MainModel: connectivity listener set');
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
    
    messages = await deleteMessageDownloads(messages);
    for (Message message in messages) {
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
      Logger.logEvent(event: 'Starting to remove played downloads');
      List<Message> downloads = await db.queryDownloads();
      List<Message> playedDownloads = downloads.where((m) => m.isplayed == 1).toList();
      await deleteMessages(playedDownloads);
    }
  }

  Future<List<Message>> recentMessages({int start, int end}) async {
    return await db.queryRecentlyPlayedMessages(start: start, end: end);
  }
}