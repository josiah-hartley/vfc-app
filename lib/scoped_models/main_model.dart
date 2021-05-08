import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/downloads_model.dart';
import 'package:voices_for_christ/scoped_models/favorites_model.dart';
import 'package:voices_for_christ/scoped_models/player_model.dart';
import 'package:voices_for_christ/scoped_models/playlists_model.dart';
import 'package:voices_for_christ/scoped_models/settings_model.dart';

class MainModel extends Model with PlayerModel, FavoritesModel, DownloadsModel, PlaylistsModel, SettingsModel {
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
  }

  Future<void> setMessagePlayed(Message message) async {
    await db.setPlayed(message);
    updateDownloadedMessage(message);
    updateFavoritedMessage(message);
    updateMessageInCurrentPlaylist(message);
    //await loadDownloads();
    //await loadFavorites();
    //notifyListeners();
  }

  Future<void> setMessageUnplayed(Message message) async {
    await db.setUnplayed(message);
    updateDownloadedMessage(message);
    updateFavoritedMessage(message);
    updateMessageInCurrentPlaylist(message);
    //await loadDownloads();
    //await loadFavorites();
    //notifyListeners();
  }

  Future<void> deleteMessages(List<Message> messages) async {
    // can't delete currently playing message
    messages.removeWhere((m) => m.id == currentlyPlayingMessage.id);
    await deleteMessageDownloads(messages);
    for (int i = 0; i < messages.length; i++) {
      // if it's in the queue, remove it
      int index = queue.indexWhere((m) => m.id == messages[i].id);
      if (index > -1) {
        removeFromQueue(index);
      }
    }
  }
}