import 'package:flutter/material.dart';
import 'package:voices_for_christ/screens/filtered_message_list.dart';

class DownloadsPage extends StatelessWidget {
  const DownloadsPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilteredMessageList(filterType: 'downloads');
  }
}