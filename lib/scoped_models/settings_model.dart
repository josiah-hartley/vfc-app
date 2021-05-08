import 'package:scoped_model/scoped_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:voices_for_christ/database/local_db.dart';

mixin SettingsModel on Model {
  final db = MessageDB.instance;
  SharedPreferences prefs;
  bool _darkMode = false;

  bool get darkMode => _darkMode;

  Future<void> loadSettings() async {
    prefs = await SharedPreferences.getInstance();
    _darkMode = prefs.getBool('darkMode') ?? false;
    notifyListeners();
  }

  void toggleDarkMode() async {
    _darkMode = !_darkMode;
    notifyListeners();
    prefs = await SharedPreferences.getInstance();
    prefs.setBool('darkMode', _darkMode);
  }
}