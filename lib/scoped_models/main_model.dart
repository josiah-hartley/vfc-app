import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/downloads_model.dart';
import 'package:voices_for_christ/scoped_models/favorites_model.dart';
import 'package:voices_for_christ/scoped_models/player_model.dart';
import 'package:voices_for_christ/scoped_models/playlists_model.dart';

class MainModel extends Model with PlayerModel, FavoritesModel, DownloadsModel, PlaylistsModel {
  void initialize() {
    initializePlayer();
    loadPlaylistsMetadata();
    loadFavorites();
    loadDownloads();
  }

  void setMessagePlayed(Message message) async {
    await db.setPlayed(message);
    loadDownloads();
    loadFavorites();
    notifyListeners();
  }

  void setMessageUnplayed(Message message) async {
    await db.setUnplayed(message);
    loadDownloads();
    loadFavorites();
    notifyListeners();
  }

  Future<void> deleteMessage(Message message) async {
    await deleteMessageDownload(message);
    // if it's in the queue, remove it
    int index = queue.indexWhere((m) => m.id == message.id);
    if (index > -1) {
      removeFromQueue(index);
    }
  }
}