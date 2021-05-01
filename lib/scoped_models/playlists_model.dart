import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';

mixin PlaylistsModel on Model {
  final db = MessageDB.instance;
  List<Playlist> _playlists = [];
  Playlist _selectedPlaylist;
  //bool _loadingSelectedPlaylist = false;
  
  List<Playlist> get playlists => _playlists;
  Playlist get selectedPlaylist => _selectedPlaylist;
  //bool get loadingSelectedPlaylist => _loadingSelectedPlaylist;

  Future<void> loadPlaylistsMetadata() async {
    _playlists = await db.getAllPlaylistsMetadata();
    // by default, playlists are sorted by date added; list most recent at top
    _playlists = _playlists.reversed.toList();
    notifyListeners();
  }

  Future<void> selectPlaylist(Playlist playlist) async {
    _selectedPlaylist = playlist;
    await loadMessagesOnCurrentPlaylist();
    //_selectedPlaylist.messages = await loadMessagesOnPlaylist(_selectedPlaylist);
  }

  /*Future<List<Message>> loadMessagesOnPlaylist(Playlist playlist) async {
    List<Message> result = await db.getMessagesOnPlaylist(playlist);
    return result;
  }*/

  Future<void> loadMessagesOnCurrentPlaylist() async {
    if (_selectedPlaylist != null) {
      //_loadingSelectedPlaylist = true;
      //notifyListeners();
      _selectedPlaylist.messages = await db.getMessagesOnPlaylist(_selectedPlaylist);
      //_loadingSelectedPlaylist = false;
      notifyListeners();
    }
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    await db.deletePlaylist(playlist);
    await loadPlaylistsMetadata();
  }

  void removeMessageFromPlaylist(int index) {
    _selectedPlaylist.messages.removeAt(index);
    notifyListeners();
  }

  void reorderPlaylist({int oldIndex, int newIndex}) {
    if (_selectedPlaylist == null) {
      return;
    }
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final Message item = _selectedPlaylist.messages.removeAt(oldIndex);
    _selectedPlaylist.messages.insert(newIndex, item);
    notifyListeners();
  }

  Future<void> saveReorderingChanges() async {
    if (_selectedPlaylist != null) {
      await db.reorderAllMessagesInPlaylist(_selectedPlaylist, _selectedPlaylist.messages);
    }
  }
}