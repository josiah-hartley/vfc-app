import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/recommendation_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/helpers/featured_message_ids.dart';

mixin RecommendationsModel on Model {
  final db = MessageDB.instance;
  List<Recommendation> _recommendations;

  List<Recommendation> get recommendations => _recommendations;

  Future<void> loadRecommendations() async {
    Recommendation _featured = await featuredMessages();
    Recommendation _downloads = await recentlyDownloaded();
    List<Recommendation> _otherRecommendations = await db.getRecommendations(
      recommendationCount: 10,
      messageCount: 10,
    );
    _recommendations = [_featured];
    if (_downloads.messages.length > 0) {
      _recommendations.add(_downloads);
    }
    _recommendations.addAll(_otherRecommendations);
    notifyListeners();
  }

  Future<void> getMoreMessagesForRecommendation(int rIndex) async {
    // MAGIC NUMBER
    int messageCount = 10;
    List<Message> result = await db.getMoreMessagesForRecommendation(
      recommendation: _recommendations[rIndex],
      messageCount: messageCount,
    );
    _recommendations[rIndex].messages.addAll(result);
    notifyListeners();
  }

  Future<Recommendation> featuredMessages() async {
    List<Message> _featuredMessages = await db.queryMultipleMessages(featuredMessageIds);
    _featuredMessages.shuffle();
    return Recommendation(
      label: 'Featured Messages',
      type: 'featured',
      messages: _featuredMessages,
    );
  }

  Future<Recommendation> recentlyDownloaded() async {
    List<Message> _recentDownloads = await db.queryDownloads(
      start: 0,
      end: 15,
      orderBy: 'downloadedat',
      ascending: false,
    );
    return Recommendation(
      label: 'Recently Downloaded',
      type: 'downloads',
      messages: _recentDownloads,
    );
  }

  Future<void> updateRecommendations({List<Message> messages, bool subtract = false}) async {
    await db.updateRecommendationsBasedOnMessages(messages: messages, subtract: subtract);
  }
}