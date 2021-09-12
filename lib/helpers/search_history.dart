import 'package:shared_preferences/shared_preferences.dart';

Future<List<String>> getSearchHistory() async {
  final _prefs = await SharedPreferences.getInstance();
  String _recentSearches = _prefs.getString('recentSearches') ?? '';
  if (_recentSearches.length < 1) { 
    return [];
  }
  return _recentSearches.split(',');
}

Future<void> addSearchToHistory(String search) async {
  final _prefs = await SharedPreferences.getInstance();
  List<String> _searchList = await getSearchHistory();

  // if search is already in history, move it to the most recent (last) spot
  int _indexOfCurrentSearch = _searchList.indexOf(search);
  if (_indexOfCurrentSearch > -1) {
    _searchList.removeAt(_indexOfCurrentSearch);
  }

  _searchList.add(search);
  
  // trim search list to only show last 15 searches
  if (_searchList.length > 15) {
    _searchList.removeAt(0);
  }

  _prefs.setString('recentSearches', _searchList.join(','));
}

Future<void> removeSearchFromHistory(int index) async {
  final _prefs = await SharedPreferences.getInstance();
  List<String> _searchList = await getSearchHistory();
  _searchList.removeAt(index);
  _prefs.setString('recentSearches', _searchList.join(','));
}