import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';

mixin FavoritesModel on Model {
  final db = MessageDB.instance;
  List<Message> _favorites = [];
  List<Message> _unplayedFavorites = [];
  List<Message> _playedFavorites = [];
  bool _favoritesLoading = false;

  List<Message> get favorites => _favorites;
  List<Message> get unplayedFavorites => _unplayedFavorites;
  List<Message> get playedFavorites => _playedFavorites;
  bool get favoritesLoading => _favoritesLoading;

  Future<void> loadFavorites() async {
    _favoritesLoading = true;
    notifyListeners();

    List<Message> result = await db.queryFavorites();

    _favorites = result;
    _unplayedFavorites = result.where((f) => f.isplayed != 1).toList();
    _playedFavorites = result.where((f) => f.isplayed == 1).toList();
    _favoritesLoading = false;
    notifyListeners();
  }

  Future<void> toggleFavorite(Message message) async {
    await db.toggleFavorite(message);
    await loadFavorites();
  }

  Future<void> setMultipleFavorites(List<Message> messages, int value) async {
    for (int i = 0; i < messages.length; i++) {
      messages[i].isfavorite = value;
      //await db.update(messages[i]);
    }
    await db.batchAddToDB(messages);
    await loadFavorites();
  }
}