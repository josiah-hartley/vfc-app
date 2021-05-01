import 'package:flutter/material.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/screens/filtered_message_list.dart';

class FavoritesPage extends StatelessWidget {
  const FavoritesPage({Key key, this.model}) : super(key: key);
  final MainModel model;

  @override
  Widget build(BuildContext context) {
    //model.loadFavorites();
    return FilteredMessageList(filterType: 'favorites');
  }
}