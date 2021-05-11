import 'package:flutter/material.dart';
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/data_models/recommendation_class.dart';
import 'package:voices_for_christ/helpers/reverse_speaker_name.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/dialogs/message_actions_dialog.dart';

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
              itemCount: model.recommendations.length,
              itemBuilder: (context, index) {
                return _recommendationCategory(context, model.recommendations[index]);
              }
            ),
          ),
        );
      }
    );
  }

  Widget _recommendationCategory(BuildContext context, Recommendation recommendation) {
    return Container(
      height: 215.0,
      padding: EdgeInsets.only(top: 14.0, bottom: 14.0, left: 14.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: EdgeInsets.only(bottom: 10.0),
            child: Text(recommendation.getHeader(), 
              style: Theme.of(context).primaryTextTheme.headline2.copyWith(fontWeight: FontWeight.w400),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              shrinkWrap: true,
              itemCount: recommendation.messages.length,
              itemBuilder: (context, index) {
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
          color: Theme.of(context).cardColor,
          margin: EdgeInsets.only(right: 14.0),
          elevation: 2.0,
          child: Container(
            padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 12.0),
            width: MediaQuery.of(context).size.width * 0.7,
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
                    maxLines: 2,
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