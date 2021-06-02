import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/helpers/logger.dart' as Logger;

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
    //_playlists = _playlists.reversed.toList();
    _playlists.sort((a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()));
    notifyListeners();
  }

  Future<void> selectPlaylist(Playlist playlist) async {
    _selectedPlaylist = playlist;
    Logger.logEvent(event: 'Selected playlist $_selectedPlaylist');
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

  Future<void> createPlaylist(String title) async {
    int id = await db.newPlaylist(title);
    if (id == null) {
      Logger.logEvent(type: 'error', event: 'Error creating new playlist');
    }
    //_playlists.insert(0, Playlist(id, DateTime.now().millisecondsSinceEpoch, title, []));
    //_playlists.add(Playlist(id, DateTime.now().millisecondsSinceEpoch, title, []));
    //_playlists.sort((a, b) => a.title.compareTo(b.title));
    int index = _playlists.indexWhere((p) => title.toLowerCase().compareTo(p.title.toLowerCase()) < 0);
    if (index < 0 || index >= _playlists.length) {
      _playlists.add(Playlist(id, DateTime.now().millisecondsSinceEpoch, title, []));
    } else {
      _playlists.insert(index, Playlist(id, DateTime.now().millisecondsSinceEpoch, title, []));
    }
    Logger.logEvent(event: 'Created new playlist: $title');
    notifyListeners();
  }

  Future<void> deletePlaylist(Playlist playlist) async {
    await db.deletePlaylist(playlist);
    _playlists.removeWhere((p) => p.id == playlist.id);
    Logger.logEvent(event: 'Deleted playlist: $playlist');
    notifyListeners();
    //await loadPlaylistsMetadata();
  }

  Future<void> editPlaylistTitle(Playlist playlist, String title) async {
    Logger.logEvent(event: 'Changing title of $playlist to $title');
    await db.editPlaylistTitle(playlist, title);
    playlist.title = title;
    int index = _playlists.indexWhere((p) => p.id == playlist.id);
    if (index > -1) {
      _playlists[index] = playlist;
      notifyListeners();
    }
  }

  void removeMessageFromCurrentPlaylistAtIndex(int index) {
    _selectedPlaylist.messages.removeAt(index);
    notifyListeners();
  }

  void addMessageToCurrentPlaylist(Message message) {
    _selectedPlaylist.messages.add(message);
    notifyListeners();
  }

  Future<void> addMessagesToPlaylist({List<Message> messages, Playlist playlist}) async {
    if (messages == null || messages.length < 1 || playlist == null) {
      return;
    }
    await Logger.logEvent(event: 'Adding messages to playlist $playlist: $messages');
    await db.addMessagesToPlaylist(
      messages: messages,
      playlist: playlist,
    );
    if (playlist.id == _selectedPlaylist?.id) {
      _selectedPlaylist.messages.addAll(messages);
      notifyListeners();
    }
  }

  void updateMessageInCurrentPlaylist(Message message) {
    if (_selectedPlaylist == null || _selectedPlaylist.messages == null) {
      return;
    }
    int index = _selectedPlaylist.messages.indexWhere((m) => m.id == message.id);
    if (index > -1) {
      _selectedPlaylist.messages[index] = message;
      notifyListeners();
    }
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

  Future<List<Playlist>> playlistsContainingMessage(Message message) async {
    List<Playlist> containing = await db.getPlaylistsContainingMessage(message);
    return containing;
  }

  Future<void> updatePlaylistsContainingMessage(Message message, List<Playlist> updatedPlaylists) async {
    await db.updatePlaylistsContainingMessage(message, updatedPlaylists);
  }
}