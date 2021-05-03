import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
//import 'package:voices_for_christ/widgets/message_display/message_metadata.dart';
import 'package:voices_for_christ/widgets/message_display/multiselect_display.dart';

class SearchResultsDisplay extends StatefulWidget {
  SearchResultsDisplay({Key key, this.searchResults, this.fullSearchCount, this.batchSize, this.loadMoreResults, this.reachedEndOfList}) : super(key: key);
  final List<Message> searchResults;
  final int fullSearchCount;
  final int batchSize;
  final Function loadMoreResults;
  final bool reachedEndOfList;

  @override
  _SearchResultsDisplayState createState() => _SearchResultsDisplayState();
}

class _SearchResultsDisplayState extends State<SearchResultsDisplay> {
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
    return Expanded(
      child: widget.searchResults.length == 0
        ? Container()
        : Container(
          child: Column(
            children: [
              _selectedMessages.length > 0
                ? Container(
                  padding: EdgeInsets.only(top: 10.0),
                  child: MultiSelectDisplay(
                    selectedMessages: _selectedMessages,
                    onDeselectAll: _deselectAll,
                  ),
                )
                : Container(
                  padding: EdgeInsets.only(top: 26.0, bottom: 26.0, left: 20.0, right: 20.0),
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: Theme.of(context).accentColor)),
                  ),
                  child: Text('${widget.fullSearchCount} RESULTS',
                    style: TextStyle(
                      color: Theme.of(context).accentColor,
                    )
                  ),
                ),
              Expanded(
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  itemCount: widget.searchResults.length + 1,
                  itemBuilder: (context, index) {
                    if (index >= widget.searchResults.length) {
                      if (!widget.reachedEndOfList) {
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
                    if (index + 1 >= widget.searchResults.length && !widget.reachedEndOfList) {
                      widget.loadMoreResults();
                    }
                    Message message = widget.searchResults[index];
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
            ],
          ),
        )
    );
  }
}