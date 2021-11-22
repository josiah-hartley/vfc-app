import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/helpers/logger.dart' as Logger;

mixin SettingsModel on Model {
  final db = MessageDB.instance;
  SharedPreferences prefs;
  bool _darkMode = false;
  bool _downloadOverData = true;
  bool _removePlayedDownloads = false;
  int _cloudLastCheckedDate = 0;

  bool get darkMode => _darkMode;
  bool get downloadOverData => _downloadOverData;
  bool get removePlayedDownloads => _removePlayedDownloads;
  int get cloudLastCheckedDate => _cloudLastCheckedDate;

  Future<void> loadSettings() async {
    Logger.logEvent(event: 'Initializing: in loadSettings(), starting to load preferences');
    try {
      prefs = await SharedPreferences.getInstance();
      Logger.logEvent(event: 'Initializing: in loadSettings(), got instance of SharedPreferences');
      _darkMode = prefs.getBool('darkMode') ?? false;
      _downloadOverData = prefs.getBool('downloadOverData') ?? true;
      _removePlayedDownloads = prefs.getBool('removePlayedDownloads') ?? false;
      Logger.logEvent(event: 'Initializing: in loadSettings(), loaded settings from preferences');
      _cloudLastCheckedDate = await db.getLastUpdatedDate();
      notifyListeners();
    } catch(e) {
      await Logger.logEvent(type: 'error', event: 'Error loading settings: $e');
    }
    Logger.logEvent(event: 'Initializing: in loadSettings(), finished!');
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