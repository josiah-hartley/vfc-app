import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/database/local_db.dart';

mixin SettingsModel on Model {
  final db = MessageDB.instance;
  SharedPreferences prefs;
  bool _darkMode = false;
  bool _downloadOverData = false;
  int _cloudLastCheckedDate = 0;

  bool get darkMode => _darkMode;
  bool get downloadOverData => _downloadOverData;
  int get cloudLastCheckedDate => _cloudLastCheckedDate;

  Future<void> loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    _downloadOverData = prefs.getBool('downloadOverData') ?? false;
    _cloudLastCheckedDate = await db.getLastUpdatedDate();
    notifyListeners();
  }

  void toggleDarkMode() async {
    _darkMode = !_darkMode;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', _darkMode);
  }

  void toggleDownloadOverData() async {
    _downloadOverData = !_downloadOverData;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('downloadOverData', _downloadOverData);
  }
}