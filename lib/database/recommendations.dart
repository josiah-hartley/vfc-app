import 'package:sqflite/sqflite.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/recommendation_class.dart';
import 'package:voices_for_christ/database/table_names.dart';

Future<void> updateRecommendationsBasedOnMessages({Database db, List<Message> messages, bool subtract = false}) async {
  String update = subtract ? 'count=count-1' : 'count=count+1';
  try {
    await db.transaction((txn) async {
      Batch batch = txn.batch();

      for (Message message in messages) {
        String values = '("${message.speaker}", "speaker")';
        List<String> tags = message.taglist == null || message.taglist == '' ? [] : message.taglist.split(',');
        tags.forEach((tag) {
          if (tag.length > 0) {
            values += ', ("$tag", "tag")';
          }
        });

        batch.rawInsert('''
          INSERT INTO $recommendationsTable(label, type) VALUES $values
            ON CONFLICT(label) DO UPDATE SET $update
        ''');
      }

      await batch.commit();
    });
  } catch(error) {
    print('Error updating recommendations in database: $error');
  }
}

Future<List<Recommendation>> getRecommendations({Database db, int limit}) async {
  try {
    var result = await db.query(recommendationsTable, columns: ['label', 'type'], orderBy: 'count DESC', limit: limit);
    if (result.isNotEmpty) {
      List<Recommendation> recommendations = [];
      result.forEach((row) {
        print(row);
        recommendations.add(Recommendation.fromMap(row));
      });
      return recommendations;
    }
    return [];
  } catch(error) {
    print('Error getting recommendations from database: $error');
    return [];
  }
}