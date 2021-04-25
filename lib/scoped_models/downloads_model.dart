import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/files/downloads.dart';

mixin DownloadsModel on Model {
  final db = MessageDB.instance;
  List<Message> _downloads = [];
  List<Message> _unplayedDownloads = [];
  List<Message> _playedDownloads = [];
  bool _downloadsLoading = false;

  List<Message> get downloads => _downloads;
  List<Message> get unplayedDownloads => _unplayedDownloads;
  List<Message> get playedDownloads => _playedDownloads;
  bool get downloadsLoading => _downloadsLoading;

  void loadDownloads() async {
    _downloadsLoading = true;
    notifyListeners();

    List<Message> result = await db.queryDownloads();

    _downloads = result;
    _unplayedDownloads = result.where((f) => f.isplayed != 1).toList();
    _playedDownloads = result.where((f) => f.isplayed == 1).toList();
    _downloadsLoading = false;
    notifyListeners();
  }

  Future<void> downloadMessage(Message message) async {
    if (message.isdownloaded == 1) {
      return;
    }

    message.iscurrentlydownloading = 1;
    notifyListeners();

    try {
      Message result = await downloadMessageFile(message);
      message = result;
      message.iscurrentlydownloading = 0;
      notifyListeners();
    }
    catch (error) {
      message.iscurrentlydownloading = 0;
      message.isdownloaded = 0;
      notifyListeners();
    }
  }

  Future<void> deleteMessageDownload(Message message) async {
    deleteMessageFile(message);
    message.isdownloaded = 0;
    message.filepath = '';
    await db.update(message);
    notifyListeners();
  }
}