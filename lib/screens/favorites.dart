import 'package:flutter/material.dart';
import 'package:voices_for_christ/screens/filtered_message_list.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return FilteredMessageList(filterType: 'favorites');
  }
}