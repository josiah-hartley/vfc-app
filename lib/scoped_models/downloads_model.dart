import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/files/downloads.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;

mixin DownloadsModel on Model {
  final db = MessageDB.instance;
  List<Message> _downloads = [];
  List<Message> _unplayedDownloads = [];
  List<Message> _playedDownloads = [];
  bool _downloadsLoading = false;
  int _currentlyLoadedDownloadsCount = 0;
  int _downloadsLoadingBatchSize = Constants.MESSAGE_LOADING_BATCH_SIZE;
  bool _reachedEndOfDownloadsList = false;

  List<Message> get downloads => _downloads;
  List<Message> get unplayedDownloads => _unplayedDownloads;
  List<Message> get playedDownloads => _playedDownloads;
  bool get downloadsLoading => _downloadsLoading;
  bool get reachedEndOfDownloadsList => _reachedEndOfDownloadsList;

  Future<void> loadDownloadsFromDB() async {
    _downloadsLoading = true;
    notifyListeners();

    List<Message> result = await db.queryDownloads(
      start: _currentlyLoadedDownloadsCount,
      end: _currentlyLoadedDownloadsCount + _downloadsLoadingBatchSize,
      //orderBy: 'speaker',
      //ascending: true,
    );

    if (result.length < _downloadsLoadingBatchSize) {
      _reachedEndOfDownloadsList = true;
    }
    _currentlyLoadedDownloadsCount += result.length;

    //_downloads = result;
    _downloads.addAll(result);
    // classify played and unplayed downloads
    List<Message> playedResult = result.where((m) => m.isplayed == 1).toList();
    List<Message> unplayedResult = result.where((m) => m.isplayed != 1).toList();
    _playedDownloads.addAll(playedResult);
    _unplayedDownloads.addAll(unplayedResult);
    _downloadsLoading = false;
    notifyListeners();
    //classifyDownloads();
  }

  /*void resetDownloadSearchParameters() {
    _downloads = [];
    _unplayedDownloads = [];
    _playedDownloads = [];
    _downloadsLoading = false;
    _currentlyLoadedDownloadsCount = 0;
    _reachedEndOfDownloadsList = false;
    notifyListeners();
  }*/

  /*void classifyDownloads() {
    _unplayedDownloads = _downloads.where((f) => f.isplayed != 1).toList();
    _playedDownloads = _downloads.where((f) => f.isplayed == 1).toList();
    notifyListeners();
  }*/

  void addMessageToDownloadedList(Message message) {
    _downloads.add(message);
    if (message.isplayed == 1) {
      _playedDownloads.add(message);
    } else {
      _unplayedDownloads.add(message);
    }
    notifyListeners();
  }

  void removeMessageFromDownloadedList(Message message) {
    _downloads.removeWhere((m) => m.id == message.id);
    if (message.isplayed == 1) {
      _playedDownloads.removeWhere((m) => m.id == message.id);
    } else {
      _unplayedDownloads.removeWhere((m) => m.id == message.id);
    }
    notifyListeners();
  }

  void updateDownloadedMessage(Message message) {
    int indexInDownloads = _downloads.indexWhere((m) => m.id == message.id);
    if (indexInDownloads > -1) {
      bool wasPreviouslyPlayed = _downloads[indexInDownloads].isplayed == 1;
      _downloads[indexInDownloads] = message;

      // classify updated download as played or unplayed;
      if (wasPreviouslyPlayed) {
        int indexInPlayedDownloads = _playedDownloads.indexWhere((m) => m.id == message.id);
        if (message.isplayed == 1) {
          _playedDownloads[indexInPlayedDownloads] = message;
        } else {
          _playedDownloads.removeAt(indexInPlayedDownloads);
          _unplayedDownloads.add(message);
        }
      } else {
        int indexInUnplayedDownloads = _unplayedDownloads.indexWhere((m) => m.id == message.id);
        if (message.isplayed == 1) {
          _unplayedDownloads.removeAt(indexInUnplayedDownloads);
          _playedDownloads.add(message);
        } else {
          _unplayedDownloads[indexInUnplayedDownloads] = message;
        }
      }
    }
    notifyListeners();
  }

  Future<void> downloadMessage(Message message) async {
    if (message.isdownloaded == 1) {
      return;
    }

    message.iscurrentlydownloading = 1;
    notifyListeners();

    try {
      //Message result = await downloadMessageFile(message);
      //message = result;
      //message.iscurrentlydownloading = 0;
      message = await downloadMessageFile(message);
      showToast('Finished downloading ${message.title}');
      addMessageToDownloadedList(message);
      notifyListeners();
    }
    catch (error) {
      message.iscurrentlydownloading = 0;
      message.isdownloaded = 0;
      showToast('Error downloading ${message.title}: check connection');
      notifyListeners();
    }
  }

  Future<void> deleteMessageDownload(Message message) async {
    try {
      message = await deleteMessageFile(message);
      //message.isdownloaded = 0;
      //message.filepath = '';
      //await db.update(message);
      removeMessageFromDownloadedList(message);
      showToast('Download deleted: ${message.title}');
      notifyListeners();
    } catch (error) {
      showToast('Error deleting download: ${message.title}');
    }
  }
}