import 'dart:ui';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/widgets/dialogs/message_actions_dialog.dart';

class HistoryDialog extends StatefulWidget {
  HistoryDialog({Key key}) : super(key: key);

  @override
  _HistoryDialogState createState() => _HistoryDialogState();
}

class _HistoryDialogState extends State<HistoryDialog> {
  final db = MessageDB.instance;
  List<Message> _recentMessages = [];
  int _recentMessageLoadedCount = 0;
  bool _reachedEndOfRecentMessages = false;
  int _totalMinutesListened = 0;

  @override
  void initState() { 
    super.initState();
    loadTotalListeningTime();
    loadRecentMessages();
  }

  void loadTotalListeningTime() async {
    int time = await db.getTotalTimeListened();
    if (time != null) {
      setState(() {
        _totalMinutesListened = time;
      });
    }
  }

  void loadRecentMessages() async {
    List<Message> result = await db.queryRecentlyPlayedMessages(
      start: _recentMessageLoadedCount,
      end: _recentMessageLoadedCount + Constants.MESSAGE_LOADING_BATCH_SIZE,
    );

    if (result.length < Constants.MESSAGE_LOADING_BATCH_SIZE) {
      _reachedEndOfRecentMessages = true;
    }

    setState(() {
      _recentMessageLoadedCount += result.length;
      _recentMessages.addAll(result);
    });
  }

  String timeListened() {
    if (_totalMinutesListened < 60) {
      return '$_totalMinutesListened minutes';
    }
    int hours = (_totalMinutesListened / 60).round();
    String result = hours == 1 ? '$hours hour' : '$hours hours';
    if (hours < 10) {
      int minutes = _totalMinutesListened % 60;
      result += ', $minutes minute';
      if (minutes != 1) {
        result += 's';
      }
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: 10.0,
          sigmaY: 10.0,
        ),
        child: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: Column(
            children: [
              _title(),
              Container(
                padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 12.0),
                child: Text('Total Listening Time: ${timeListened()}',
                  style: Theme.of(context).primaryTextTheme.headline3,
                ),
              ),
              Expanded(
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListView.builder(
                    itemCount: _recentMessages.length + 1,
                    itemBuilder: (context, index) {
                      if (index >= _recentMessages.length) {
                        if (_reachedEndOfRecentMessages) {
                          return SizedBox(height: 250.0); 
                        }
                        return Container(
                          height: 250.0,
                          alignment: Alignment.center,
                          child: Container(
                            height: 50.0,
                            width: 50.0,
                            child: CircularProgressIndicator(),
                          ),
                        );
                      }
                      if (index + Constants.MESSAGE_LOADING_BATCH_SIZE / 2 >= _recentMessages.length && !_reachedEndOfRecentMessages) {
                        loadRecentMessages();
                      }

                      Message message = _recentMessages[index];
                      DateTime d = DateTime.fromMillisecondsSinceEpoch(message.lastplayeddate ?? 0.0);
                      int hour = d.hour > 12 ? d.hour - 12 : d.hour;
                      // change 0 hour to 12 am
                      if (hour == 0) { hour = 12; }
                      String minute = d.minute < 10 ? '0${d.minute}' : '${d.minute}';
                      String ampm = d.hour > 12 ? 'pm' : 'am';
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
                          color: Theme.of(context).backgroundColor.withOpacity(0.01),
                          padding: EdgeInsets.symmetric(vertical: 15.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                padding: EdgeInsets.only(bottom: 8.0),
                                child: Text(message.title,
                                  style: Theme.of(context).primaryTextTheme.headline2.copyWith(fontSize: 16.0),
                                ),
                              ),
                              Container(
                                padding: EdgeInsets.only(bottom: 6.0),
                                child: Text(message.speaker,
                                  style: Theme.of(context).primaryTextTheme.headline3,
                                ),
                              ),
                              Container(
                                alignment: Alignment.centerRight,
                                child: Text('${d.month}/${d.day}/${d.year} at $hour:$minute $ampm',
                                  style: Theme.of(context).primaryTextTheme.headline4,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _title() {
    List<Widget> _titleChildren = [
      GestureDetector(
        child: Container(
          color: Theme.of(context).backgroundColor.withOpacity(0.01),
          padding: EdgeInsets.only(left: 16.0, right: 28.0, top: 54.0, bottom: 14.0),
          child: Icon(CupertinoIcons.back, 
            size: 32.0,
            color: Theme.of(context).accentColor
          ),
        ),
        onTap: () { Navigator.of(context).pop(); },
      ),
      Expanded(
        child: Container(
          padding: EdgeInsets.only(top: 52.0, bottom: 12.0, left: 16.0, right: 16.0),
          child: Text('History',
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).primaryTextTheme.headline1.copyWith(
              fontSize: 20.0,
            ),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    ];

    return Container(
      child: Row(
        children: _titleChildren,
      ),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(
          color: Theme.of(context).accentColor
        ))
      ),
    );
  }
}