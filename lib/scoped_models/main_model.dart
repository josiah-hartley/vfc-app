import 'package:connectivity/connectivity.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/pause_reason.dart';
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

  Future<void> initialize() async {
    await initializePlayer(onChangedMessage: (Message message) {
      updateDownloadedMessage(message);
      updateFavoritedMessage(message);
      updateMessageInCurrentPlaylist(message);
    });
    await loadPlaylistsMetadata();
    await loadFavoritesFromDB();
    await loadDownloadedMessagesFromDB();
    await loadDownloadQueueFromDB();
    await loadStorageUsage();
    await loadSettings();
    await loadRecommendations();
    await deletePlayedDownloads();

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

  Future<void> toggleFavorite(Message message) async {
    await handleFavoriteToggling(message);
    bool subtract = message.isfavorite != 1;
    await updateRecommendations(messages: [message], subtract: subtract);
  }

  Future<void> queueDownloads(List<Message> messages) async {
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
}