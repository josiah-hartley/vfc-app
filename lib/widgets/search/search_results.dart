import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';

Widget searchResultsDisplay({List<Message> searchResults,
  int fullSearchCount,
  int batchSize,
  Function loadMoreResults,
  bool reachedEndOfList}) {
  
  return Expanded(
    child: searchResults.length == 0
      ? Container()
      : Container(
        child: Column(
          children: [
            Container(
              child: Text('$fullSearchCount results'),
            ),
            Expanded(
              /*child: ListView.builder(
                itemCount: 676,
                itemBuilder: (context, index) {
                  String alphabet = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ';
                  int firstIndex = index % 26;
                  int secondIndex = index ~/ 26;
                  String initials = alphabet[firstIndex] + ' ' + alphabet[secondIndex];
                  return Container(
                    child: Center(
                      child: initialSticker(
                        name: initials,
                      )
                    ),
                  );
                },
              ),*/
              child: ListView.builder(
                //key: PageStorageKey('search-results'),
                itemCount: searchResults.length + 1,
                itemBuilder: (context, index) {
                  if (index >= searchResults.length) {
                    if (!reachedEndOfList) {
                      return Container(
                        height: 100.0,
                        child: Center(child: Text('LOADING')),
                      );
                    }
                    return Container(
                      height: 100.0,
                      child: Center(child: Text('END OF LIST')),
                    );
                  }
                  if (index + 1 >= searchResults.length && !reachedEndOfList) {
                    loadMoreResults();
                  }
                  return MessageCard(message: searchResults[index]);
                },
              ),
            ),
          ],
        ),
      )
  );
}