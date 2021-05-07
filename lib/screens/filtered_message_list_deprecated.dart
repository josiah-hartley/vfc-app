/*import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
import 'package:voices_for_christ/widgets/message_display/multiselect_display.dart';

class FilteredMessageList extends StatefulWidget {
  FilteredMessageList({Key key, this.filterType}) : super(key: key);
  final String filterType;

  @override
  _FilteredMessageListState createState() => _FilteredMessageListState();
}

class _FilteredMessageListState extends State<FilteredMessageList> {
  String _filter = 'All';
  LinkedHashSet<Message> _selectedMessages = LinkedHashSet();

  /*void loadMessages(MainModel model) async {
    if (widget.filterType == 'favorites') {
      await model.loadFavorites();
    }
    if (widget.filterType == 'downloads') {
      await model.loadDownloads();
    }
  }*/

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
        List<Message> allDownloads = [];
        if (widget.filterType == 'downloads') {

        }
        //loadMessages(model);
        return Container(
          child: Column(
            children: [
              //_filterButtonsRow(),
              _selectedMessages.length > 0
                ? MultiSelectDisplay(
                  selectedMessages: _selectedMessages,
                  onDeselectAll: _deselectAll,
                )
                : _filterButtonsRow(),
              _filteredList(
                isLoading: widget.filterType == 'favorites' ? model.favoritesLoading : model.downloadsLoading,
                fullList: widget.filterType == 'favorites' ? model.favorites : model.downloads,
                unplayedList: widget.filterType == 'favorites' ? model.unplayedFavorites : model.unplayedDownloads,
                playedList: widget.filterType == 'favorites' ? model.playedFavorites : model.playedDownloads,
                fullEmptyMessage: widget.filterType == 'favorites' ? 'If you mark any messages as favorites, they will appear here' : 'If you download any messages, they will appear here',
                unplayedEmptyMessage: widget.filterType == 'favorites' ? 'Any unplayed favorites will appear here' : 'Any unplayed downloads will appear here',
                playedEmptyMessage: widget.filterType == 'favorites' ? 'Any played favorites will appear here' : 'Any played downloads will appear here',
                reachedEndOfList: widget.filterType == 'favorites' ? model.reachedEndOFavoritesList : model.reachedEndOfDownloadsList,
                loadMoreResults: widget.filterType == 'favorites' ? model.loadFavoritesFromDB : model.loadDownloadsFromDB,
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
          borderRadius: BorderRadius.circular(20.0),
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
}*/