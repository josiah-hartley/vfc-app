import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/helpers/minimize_keyboard.dart';
import 'package:voices_for_christ/widgets/search/search_input.dart';
import 'package:voices_for_christ/widgets/search/search_results.dart';
import 'package:voices_for_christ/helpers/logger.dart' as Logger;

class SearchWindow extends StatefulWidget {
  SearchWindow({Key key, this.focusNode, this.closeWindow}) : super(key: key);
  final FocusNode focusNode;
  final Function closeWindow;

  @override
  _SearchWindowState createState() => _SearchWindowState();
}

class _SearchWindowState extends State<SearchWindow> {
  final TextEditingController _searchController = TextEditingController();
  final db = MessageDB.instance;
  List<Message> _searchResults = [];
  int _fullSearchResultCount = 0;
  int _currentlyLoadedMessageCount = 0;
  int _messageLoadingBatchSize = Constants.MESSAGE_LOADING_BATCH_SIZE;
  bool _hasSearched = false;
  bool _reachedEndOfList = false;
  bool _waitingForResults = false;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.only(top: 12.0),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
          searchInput(
            context: context,
            focusNode: widget.focusNode,
            closeWindow: widget.closeWindow,
            searchController: _searchController,
            onChanged: (String searchString) { setState(() {}); },
            onSearch: () {
              _onSearch(context);
            },
            onClearSearchString: () {
              setState(() {
                _searchController.text = '';
                _hasSearched = false;
                _resetSearchParameters();
              });
            }
          ),
          SearchResultsDisplay(
            hasSearched: _hasSearched,
            searchResults: _searchResults,
            fullSearchCount: _fullSearchResultCount,
            batchSize: _messageLoadingBatchSize,
            loadMoreResults: _search,
            reachedEndOfList: _reachedEndOfList,
          ),
          ],
        ),
      ),
      decoration: BoxDecoration(
        color: Theme.of(context).backgroundColor,
      ),
    );
  }

  void _onSearch(BuildContext context) async {
    await _initializeNewSearch(context);
  }

  Future<void> _initializeNewSearch(BuildContext context) async {
    if (context != null) {
      minimizeKeyboard(context);
    }
    if (_waitingForResults) {
      return;
    }
    // lock the search so that two searches won't happen simultaneously
    _waitingForResults = true;

    try {
      _resetSearchParameters();
      int _count = await db.searchCountSpeakerTitle(_searchController.text);
      setState(() {
        _fullSearchResultCount = _count;
      });

      await _search();
    } catch(e) {
      print(e);
    }
    // unlock search
    _waitingForResults = false;
  }

  void _resetSearchParameters() {
    setState(() {
      _searchResults = [];
      _currentlyLoadedMessageCount = 0;
      _reachedEndOfList = false;
      _fullSearchResultCount = 0;
    });
  }

  Future<void> _search() async {
    List<Message> result = [];

    if (_searchController.text != '') {
      result = await db.searchBySpeakerOrTitle(
        searchTerm: _searchController.text, 
        start: _currentlyLoadedMessageCount, 
        end: _currentlyLoadedMessageCount + _messageLoadingBatchSize
      );

      if (result.length < _messageLoadingBatchSize) {
        _reachedEndOfList = true;
      }
      _currentlyLoadedMessageCount += result.length;
      setState(() {
        _hasSearched = true;
      });
      Logger.logEvent(event: 'Searching for ${_searchController.text}; total number of results is $_fullSearchResultCount; currently loaded results: $_currentlyLoadedMessageCount; reached end of list is $_reachedEndOfList');
    }
    setState(() {
      _searchResults.addAll(result);
    });
  }
}