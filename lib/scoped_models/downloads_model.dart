import 'dart:collection';
import 'package:connectivity/connectivity.dart';
import 'package:dio/dio.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/download_class.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/files/delete_files.dart';
import 'package:voices_for_christ/files/download_files.dart';
import 'package:voices_for_christ/helpers/toasts.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;

mixin DownloadsModel on Model {
  final db = MessageDB.instance;
  final dio = Dio();
  Queue<Download> _currentlyDownloading = Queue();
  Queue<Download> _downloadQueue = Queue();
  List<Message> _downloads = [];
  List<Message> _unplayedDownloads = [];
  List<Message> _playedDownloads = [];
  bool _downloadsLoading = false;
  int _currentlyLoadedDownloadsCount = 0;
  int _downloadsLoadingBatchSize = Constants.MESSAGE_LOADING_BATCH_SIZE;
  bool _reachedEndOfDownloadsList = false;
  int _downloadedBytes = 0;

  Queue<Download> get currentlyDownloading => _currentlyDownloading;
  Queue<Download> get downloadQueue => _downloadQueue;
  List<Message> get downloads => _downloads;
  /*List<Message> get downloads {
    List<Message> result = _currentlyDownloading.map((e) => e.message).toList();
    List<Message> queue = _downloadQueue.map((e) => e.message).toList();
    result.addAll(queue);
    result.addAll(_downloads);
    return result;
  }*/
  List<Message> get unplayedDownloads => _unplayedDownloads;
  List<Message> get playedDownloads => _playedDownloads;
  bool get downloadsLoading => _downloadsLoading;
  bool get reachedEndOfDownloadsList => _reachedEndOfDownloadsList;
  int get downloadedBytes => _downloadedBytes;

  Future<void> loadStorageUsage() async {
    _downloadedBytes = await db.getStorageUsed();
    notifyListeners();
  }

  Future<void> loadDownloadedMessagesFromDB() async {
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
          if (indexInPlayedDownloads > -1) {
            _playedDownloads[indexInPlayedDownloads] = message;
          }
        } else {
          if (indexInPlayedDownloads > -1) {
            _playedDownloads.removeAt(indexInPlayedDownloads);
          }
          _unplayedDownloads.add(message);
        }
      } else {
        int indexInUnplayedDownloads = _unplayedDownloads.indexWhere((m) => m.id == message.id);
        if (message.isplayed == 1) {
          if (indexInUnplayedDownloads > -1) {
            _unplayedDownloads.removeAt(indexInUnplayedDownloads);
          }
          _playedDownloads.add(message);
        } else {
          if (indexInUnplayedDownloads > -1) {
            _unplayedDownloads[indexInUnplayedDownloads] = message;
          }
        }
      }
    }
    notifyListeners();
  }

  /*void addMessageToDownloadQueue(Message message) {
    CancelToken cancelToken = CancelToken();
    Download task = Download(
      message: message,
      cancelToken: cancelToken,
    );

    if (_currentlyDownloading.length <= Constants.ACTIVE_DOWNLOAD_QUEUE_SIZE) {
      _currentlyDownloading.add(task);
      executeDownloadTask(task);
    } else {
      _downloadQueue.add(task);
    }
  }*/

  Future<void> loadDownloadQueueFromDB() async {
    List<Message> result = await db.getDownloadQueueFromDB();
    addMessagesToDownloadQueue(result);
  }

  void addMessagesToDownloadQueue(List<Message> messages) {
    db.addMessagesToDownloadQueueDB(messages);
    List<Download> tasks = [];
    messages.forEach((message) {
      if (message.isdownloaded != 1) {
        CancelToken token = CancelToken();
        tasks.add(Download(
          message: message,
          cancelToken: token,
        ));
      }
    });

    tasks.forEach((task) {
      if (_currentlyDownloading.length < Constants.ACTIVE_DOWNLOAD_QUEUE_SIZE) {
        print('DOWNLOADQUEUE: adding ${task.message.title} to currently downloading');
        _currentlyDownloading.add(task);
        executeDownloadTask(task);
      } else {
        print('DOWNLOADQUEUE: adding ${task.message.title} to download queue');
        _downloadQueue.add(task);
      }
    });
  }

  void advanceDownloadsQueue() {
    print('DOWNLOADQUEUE: advancing download queue');
    if (_downloadQueue.length < 1) {
      return;
    }
    Download result = _downloadQueue.removeFirst();
    print('DOWNLOADQUEUE: moving ${result.message.title} to active downloads');
    _currentlyDownloading.add(result);
    notifyListeners();
    executeDownloadTask(result);
  }

  void executeDownloadTask(Download task) async {
    print('DOWNLOADQUEUE: executing download task: ${task.message.title}');
    if (task.message == null || task.message.isdownloaded == 1) {
      return;
    }

    try {
      task.message.iscurrentlydownloading = 1;
      task.message = await downloadMessageFile(
        task: task,
        onReceiveProgress: (int current, int total) {
          task.bytesReceived = current;
          task.size = total;
          notifyListeners();
        }
      );
      finishDownload(task);
    } on Exception catch(error) {
      task.message.iscurrentlydownloading = 0;
      task.message.isdownloaded = 0;
      await db.update(task.message);

      if (error.toString().indexOf('DioErrorType.cancel') > -1) {
        
        showToast('Canceled download: ${task.message.title}');
      } else {
        print('Error executing download task: $error');
        showToast('Error downloading ${task.message.title}: check connection');
        ConnectivityResult connection = await Connectivity().checkConnectivity();
        if (connection == ConnectivityResult.none) {
          // pause all downloads
        } else {
          //advanceDownloadsQueue();
        }
      }
    }
  }

  void finishDownload(Download task) async {
    task.message.iscurrentlydownloading = 0;
    task.message.downloadedat = DateTime.now().millisecondsSinceEpoch;
    await db.update(task.message);
    _downloadedBytes += task.size;
    await db.updateStorageUsed(
      bytes: task.size,
      add: true,
    );
    showToast('Finished downloading ${task.message.title}');
    addMessageToDownloadedList(task.message);
    _currentlyDownloading.removeWhere((t) => t.message.id == task.message.id);
    db.removeMessagesFromDownloadQueueDB([task.message]);
    advanceDownloadsQueue();
  }

  void cancelDownload(Download task) {
    task.cancelToken.cancel();
    _currentlyDownloading.removeWhere((t) => t.message?.id == task.message?.id);
    _downloadQueue.removeWhere((t) => t.message?.id == task.message?.id);
    if (_currentlyDownloading.length < Constants.ACTIVE_DOWNLOAD_QUEUE_SIZE) {
      advanceDownloadsQueue();
    }
    db.removeMessagesFromDownloadQueueDB([task.message]);
    notifyListeners();
  }

  /*Future<void> downloadMessage(Message message) async {
    if (message.isdownloaded == 1) {
      return;
    }

    message.iscurrentlydownloading = 1;
    notifyListeners();

    try {
      message = await downloadMessageFile(message);
      await db.update(message);
      showToast('Finished downloading ${message.title}');
      addMessageToDownloadedList(message);
      notifyListeners();
    }
    catch (error) {
      message.iscurrentlydownloading = 0;
      message.isdownloaded = 0;
      await db.update(message);
      showToast('Error downloading ${message.title}: check connection');
      notifyListeners();
    }
  }*/

  Future<void> deleteMessageDownloads(List<Message> messages) async {
    try {
      int totalStorage = await deleteMessageFiles(messages);
      for (int i = 0; i < messages.length; i++) {
        messages[i].isdownloaded = 0;
        messages[i].filepath = '';
        removeMessageFromDownloadedList(messages[i]);
      }
      await db.batchAddToDB(messages);
      _downloadedBytes -= totalStorage;
      await db.updateStorageUsed(
        bytes: totalStorage,
        add: false,
      );
      
      if (messages.length == 1) {
        showToast('Removed ${messages[0].title} from downloads');
      } else {
        showToast('Removed ${messages.length} downloads');
      }
      notifyListeners();
    } catch (error) {
      showToast('Error removing downloads');
    }
  }
}