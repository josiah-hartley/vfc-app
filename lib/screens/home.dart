import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/recommendation_class.dart';
import 'package:voices_for_christ/helpers/duration_in_minutes.dart';
import 'package:voices_for_christ/helpers/reverse_speaker_name.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/message_actions_dialog.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;

class HomePage extends StatelessWidget {
  const HomePage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        return Container(
          child: Container(
            alignment: Alignment.topCenter,
            child: ListView.builder(
              padding: EdgeInsets.only(top: 0.0, bottom: 250.0),
              shrinkWrap: true,
              itemCount: model.recommendations.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return Container(
                    padding: EdgeInsets.only(top: 12.0, left: 14.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text('Recommendations',
                            style: Theme.of(context).primaryTextTheme.headline1,
                          )
                        ),
                        Container(
                          child: IconButton(
                            icon: Icon(CupertinoIcons.question_circle,
                              color: Theme.of(context).accentColor,
                            ),
                            onPressed: () {
                              showDialog(
                                context: context, 
                                builder: (context) => AlertDialog(
                                  title: Container(
                                    child: Text('Recommendations',
                                      style: TextStyle(color: Theme.of(context).accentColor),
                                    ),
                                  ),
                                  content: Container(
                                    child: Text('At first, the recommended messages on the home page come from pre-selected categories.  Over time, these recommendations will update based on speakers and topics related to messages that you download and favorite.',
                                      style: TextStyle(color: Theme.of(context).accentColor),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }
                return _recommendationCategory(
                  context: context, 
                  recommendation: model.recommendations[index - 1],
                  onLoadMore: () {
                    model.getMoreMessagesForRecommendation(index - 1);
                  }
                );
              }
            ),
          ),
        );
      }
    );
  }

  Widget _recommendationCategory({BuildContext context, Recommendation recommendation, Function onLoadMore}) {
    return Container(
      height: 255.0,
      padding: EdgeInsets.only(top: 30.0, bottom: 30.0, left: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(recommendation.getHeader(), 
              style: Theme.of(context).primaryTextTheme.headline2.copyWith(fontWeight: FontWeight.w300, fontSize: 24.0),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: recommendation.messages.length + 1,
              itemBuilder: (context, index) {
                if (index >= recommendation.messages.length) {
                  if (recommendation.type == 'featured' || recommendation.type == 'downloads') {
                    return Container();
                  }
                  return _loadMoreButton(context, onLoadMore);
                }
                return _recommendedMessageCard(context, recommendation.messages[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _recommendedMessageCard(BuildContext context, Message message) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context, 
          builder: (context) {
            return MessageActionsDialog(
              message: message,
            );
          }
        );
      },
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
        child: Card(
          //color: Theme.of(context).cardColor,
          margin: EdgeInsets.only(right: 14.0),
          elevation: 2.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).backgroundColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            width: min(MediaQuery.of(context).size.width * 0.7, Constants.MAX_RECOMMENDATION_WIDTH),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(message.title, 
                  style: Theme.of(context).primaryTextTheme.headline3.copyWith(fontSize: 20.0, fontWeight: FontWeight.w400),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                Container(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 0.0),
                  child: Text(speakerReversedName(message.speaker), 
                    style: Theme.of(context).primaryTextTheme.headline4.copyWith(fontSize: 18.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  alignment: Alignment.centerRight,
                  child: Text(message.durationinseconds == null ? '${message.approximateminutes} min' : messageDurationInMinutes(message.durationinseconds), 
                    style: Theme.of(context).primaryTextTheme.headline4.copyWith(fontSize: 18.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _loadMoreButton(BuildContext context, Function onPressed) {
    return GestureDetector(
      onTap: onPressed,
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 5.0, horizontal: 4.0),
        child: Card(
          margin: EdgeInsets.only(right: 14.0),
          elevation: 2.0,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Theme.of(context).cardColor,
                  Theme.of(context).backgroundColor.withOpacity(0.7),
                ],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            width: min(MediaQuery.of(context).size.width * 0.7, Constants.MAX_RECOMMENDATION_WIDTH),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  child: Icon(CupertinoIcons.add,
                    size: 48.0,
                    color: Theme.of(context).accentColor,
                  ),
                ),
                Container(
                  alignment: Alignment.center,
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 0.0),
                  child: Text('Load More', 
                    style: Theme.of(context).primaryTextTheme.headline2.copyWith(fontSize: 22.0),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}