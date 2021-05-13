import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
import 'package:voices_for_christ/widgets/message_display/multiselect_display.dart';

class FavoritesPage extends StatefulWidget {
  FavoritesPage({Key key}) : super(key: key);

  @override
  _FavoritesPageState createState() => _FavoritesPageState();
}

class _FavoritesPageState extends State<FavoritesPage> {
  String _filter = 'All';
  LinkedHashSet<Message> _selectedMessages = LinkedHashSet();

  void _toggleMessageSelection(Message message) {
    setState(() {
      if (_selectedMessages.contains(message)) {
        _selectedMessages.remove(message);
      } else {
        if (_selectedMessages.length < Constants.MESSAGE_SELECTION_LIMIT) {
          _selectedMessages.add(message);
        }
      }
    });
  }

  void _deselectAll() {
    setState(() {
      _selectedMessages = LinkedHashSet();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScopedModelDescendant<MainModel>(
      builder: (context, child, model) {
        return Container(
          child: Column(
            children: [
              _selectedMessages.length > 0
                ? MultiSelectDisplay(
                  selectedMessages: _selectedMessages,
                  onDeselectAll: _deselectAll,
                )
                : _filterButtonsRow(),
              _filteredList(
                isLoading: model.favoritesLoading,
                fullList: model.favorites,
                unplayedList: model.unplayedFavorites,
                playedList: model.playedFavorites,
                fullEmptyMessage: 'If you mark any messages as favorites, they will appear here',
                unplayedEmptyMessage: 'Any unplayed favorites will appear here',
                playedEmptyMessage: 'Any played favorites will appear here',
                reachedEndOfList: model.reachedEndOFavoritesList,
                loadMoreResults: model.loadFavoritesFromDB,
              )
            ],
          ),
        );
      },
    );
  }

  Widget _filterButtonsRow() {
    return Container(
      padding: EdgeInsets.symmetric(vertical: 10.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(3, (index) {
          List<String> _categories = ['All', 'Unplayed', 'Played'];
          return _filterButton(
            text: _categories[index],
            selected: _filter == _categories[index],
            onPressed: () {
              setState(() {
                _filter = _categories[index];
              });
            }
          );
        }),
      ),
    );
  }

  Widget _filterButton({String text, bool selected, Function onPressed}) {
    return GestureDetector(
      child: Container(
        decoration: BoxDecoration(
          color: selected ? Theme.of(context).accentColor.withOpacity(1.0) : Colors.transparent,
          borderRadius: BorderRadius.circular(5.0),
          /*border: Border.all(
            color: selected ? Theme.of(context).accentColor.withOpacity(0.15) : Colors.transparent,
          )*/
        ),
        padding: EdgeInsets.symmetric(horizontal: 20.0, vertical: 10.0),
        margin: EdgeInsets.symmetric(horizontal: 0.0),
        child: Text(text,
          style: selected 
            ? Theme.of(context).accentTextTheme.headline3.copyWith(color: Theme.of(context).primaryColor) 
            : Theme.of(context).primaryTextTheme.headline3,
        ),
      ),
      onTap: onPressed,
    );
  }

  Widget _filteredList({
      bool isLoading, 
      List<Message> fullList, 
      List<Message> unplayedList, 
      List<Message> playedList,
      String fullEmptyMessage,
      String unplayedEmptyMessage,
      String playedEmptyMessage,
      bool reachedEndOfList,
      Function loadMoreResults,
    }) {
      List<Message> messageList;
      String emptyMessage = '';
      switch(_filter) {
        case 'All':
          messageList = fullList;
          emptyMessage = fullEmptyMessage;
          break;
        case 'Unplayed':
          messageList = unplayedList;
          emptyMessage = unplayedEmptyMessage;
          break;
        case 'Played':
          messageList = playedList;
          emptyMessage = playedEmptyMessage;
          break;
        default:
          messageList = fullList;
      }

      if (messageList.length < 1) {
        return Expanded(
          child: Container(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 150.0),
            child: isLoading 
              ? CircularProgressIndicator()
              : Text(emptyMessage,
                style: Theme.of(context).primaryTextTheme.headline1,
                textAlign: TextAlign.center,
              ),
          ),
        );
      }
      
      return Expanded(
        child: Container(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 0.0),
            itemCount: messageList.length + 1,
            itemBuilder: (context, index) {
              if (index >= messageList.length) {
                if (reachedEndOfList) {
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
              if (index + Constants.MESSAGE_LOADING_BATCH_SIZE / 2 >= messageList.length && !reachedEndOfList) {
                loadMoreResults();
              }
              Message message = messageList[index];
              return MessageCard(
                message: message,
                selected: _selectedMessages.contains(message),
                onSelect: () {
                  _toggleMessageSelection(message);
                },
              );
            },
          ),
        ),
      );
  }
}