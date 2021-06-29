import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/filter_message_list.dart';
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
  String _searchTerm = '';
  bool _searchOpen = false;

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

  void _toggleSearch() {
    setState(() {
      _searchTerm = '';
      _searchOpen = !_searchOpen;
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
                : _filterButtonsRow(model.sortFavorites),
              _messageCountAndSearch(
                context: context,
                total: model.totalFavoritesCount,
                played: model.playedFavoritesCount,
              ),
              _filteredList(
                isLoading: model.favoritesLoading,
                searchTerm: _searchTerm,
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

  Widget _filterButtonsRow(Function sortFavorites) {
    return Container(
      padding: EdgeInsets.only(top: 6.0, bottom: 5.0),
      child: Row(
        children: [
          Expanded(
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
          ),
          _sortActions(sortFavorites),
        ],
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

  Widget _sortActions(Function sortFavorites) {
    return Container(
      color: Theme.of(context).backgroundColor.withOpacity(0.01),
      child: PopupMenuButton<int>(
        icon: Icon(CupertinoIcons.ellipsis_vertical,
          color: Theme.of(context).accentColor,
          size: 24.0,
        ),
        color: Theme.of(context).primaryColor,
        shape: Border.all(color: Theme.of(context).accentColor.withOpacity(0.4)),
        elevation: 20.0,
        itemBuilder: (context) {
          return [
            _listAction(
              value: 0,
              text: 'Sort by Speaker A-Z',
            ),
            _listAction(
              value: 1,
              text: 'Sort by Speaker Z-A',
            ),
            _listAction(
              value: 2,
              text: 'Sort by Title A-Z',
            ),
            _listAction(
              value: 3,
              text: 'Sort by Title Z-A',
            ),
          ];
        },
        onSelected: (value) {
          switch(value) {
            case 0:
              sortFavorites(
                orderBy: 'speaker',
                ascending: true,
              );
              break;
            case 1:
              sortFavorites(
                orderBy: 'speaker',
                ascending: false,
              );
              break;
            case 2:
              sortFavorites(
                orderBy: 'title',
                ascending: true,
              );
              break;
            case 3:
              sortFavorites(
                orderBy: 'title',
                ascending: false,
              );
              break;
          }
        },
      ),
    );
  }

  PopupMenuItem<int> _listAction({int value, IconData icon, String text}) {
    return PopupMenuItem<int>(
      value: value,
      child: Container(
        child: Row(
          children: [
            icon == null
              ? Container()
              : Container(
                child: Icon(icon,
                  color: Theme.of(context).accentColor,
                  size: 22.0,
                ),
              ),
            Container(
              width: MediaQuery.of(context).size.width / 2,
              padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 14.0),
              child: Text(text,
                style: TextStyle(
                  color: Theme.of(context).accentColor,
                  fontSize: 16.0,
                )
              )
            ),
          ],
        )
      ),
    );
  }

  Widget _messageCountAndSearch({BuildContext context, int total, int played}) {
    String countDisplay = '';
    switch(_filter) {
      case 'All':
        if (total > 0) {
          countDisplay = '$total Favorite Message';
          if (total > 1) {
            countDisplay += 's';
          }
        }
        break;
      case 'Unplayed':
        if (total - played > 0) {
          countDisplay = '${total - played} Unplayed Favorite';
          if (total - played > 1) {
            countDisplay += 's';
          }
        }
        break;
      case 'Played':
        if (played > 0) {
          countDisplay = '$played Played Favorite';
          if (played > 1) {
            countDisplay += 's';
          }
        }
        break;
    }

    Widget _countMessage = countDisplay == ''
      ? SizedBox(height: 48.0)
      : Container(
      padding: EdgeInsets.only(top: 16.0, bottom: 15.0),
      alignment: Alignment.center,
      child: Text(countDisplay,
        style: Theme.of(context).primaryTextTheme.headline2.copyWith(
          fontSize: 14.0, 
          color: Theme.of(context).accentColor.withOpacity(0.8),
        ),
      ),
    );

    Widget _searchBox = Container(
      child: TextField(
        onChanged: (String filterString) {
          setState(() {
            _searchTerm = filterString;
          });
        },
        autofocus: true,
        textInputAction: TextInputAction.done,
        cursorColor: Theme.of(context).accentColor,
        cursorWidth: 2.0,
        style: TextStyle(
          color: Theme.of(context).accentColor,
          fontSize: 24.0,
        ),
        decoration: InputDecoration(
          hintText: 'Filter by topic or speaker',
          hintStyle: TextStyle(
            color: Theme.of(context).accentColor.withOpacity(0.6),
            fontSize: 18.0,
          ),
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: EdgeInsets.only(left: 12.0, right: 12.0),
        ),
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
          colors: [
            Theme.of(context).accentColor.withOpacity(0.1),
            Theme.of(context).accentColor.withOpacity(0.2),
          ]
        ),
      ),
    );

    return Container(
      padding: EdgeInsets.only(bottom: 5.0),
      child: Row(
        children: [
          SizedBox(width: 38.0),
          Expanded(
            child: Container(
              alignment: Alignment.center,
              child: _searchOpen ? _searchBox : _countMessage,
            ),
          ),
          GestureDetector(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              color: Theme.of(context).backgroundColor.withOpacity(0.01),
              width: 38.0,
              child: Icon(_searchOpen ? CupertinoIcons.xmark_circle : Icons.filter_list_rounded,
                size: 30.0,
                color: Theme.of(context).accentColor,
              ),
            ),
            onTap: _toggleSearch,
          ),
        ],
      ),
    );
  }

  Widget _filteredList({
      bool isLoading, 
      String searchTerm,
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
      List<Message> filteredMessageList = filterMessageList(
        messages: messageList,
        searchTerm: searchTerm,
      );

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

      if (filteredMessageList.length < 1) {
        return Expanded(
          child: Container(
            alignment: Alignment.topCenter,
            padding: EdgeInsets.only(top: 150.0),
            child: isLoading 
              ? CircularProgressIndicator()
              : Text('No favorites match that search filter',
                style: Theme.of(context).primaryTextTheme.headline2,
                textAlign: TextAlign.center,
              ),
          ),
        );
      }
      
      return Expanded(
        child: Container(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 0.0),
            itemCount: filteredMessageList.length + 1,
            itemBuilder: (context, index) {
              if (index >= filteredMessageList.length) {
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
              Message message = filteredMessageList[index];
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