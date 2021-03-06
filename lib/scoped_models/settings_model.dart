import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/database/local_db.dart';

mixin SettingsModel on Model {
  final db = MessageDB.instance;
  SharedPreferences prefs;
  bool _darkMode = false;
  bool _downloadOverData = false;
  bool _removePlayedDownloads = false;
  int _cloudLastCheckedDate = 0;

  bool get darkMode => _darkMode;
  bool get downloadOverData => _downloadOverData;
  bool get removePlayedDownloads => _removePlayedDownloads;
  int get cloudLastCheckedDate => _cloudLastCheckedDate;

  Future<void> loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _downloadOverData = prefs.getBool('downloadOverData') ?? false;
    _removePlayedDownloads = prefs.getBool('removePlayedDownloads') ?? false;
    _cloudLastCheckedDate = await db.getLastUpdatedDate();
    notifyListeners();
  }

  void toggleDarkMode() async {
    _darkMode = !_darkMode;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', _darkMode);
  }

  void changeDownloadOverDataStoredSetting() async {
    _downloadOverData = !_downloadOverData;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('downloadOverData', _downloadOverData);
  }

  void toggleRemovePlayedDownloads() async {
    _removePlayedDownloads = !_removePlayedDownloads;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('removePlayedDownloads', _removePlayedDownloads);
  }
}