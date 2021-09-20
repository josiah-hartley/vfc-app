import 'dart:collection';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
import 'package:voices_for_christ/helpers/filter_message_list.dart';
import 'package:voices_for_christ/helpers/pause_reason.dart';
import 'package:voices_for_christ/scoped_models/main_model.dart';
import 'package:voices_for_christ/widgets/message_display/message_card.dart';
import 'package:voices_for_christ/widgets/message_display/multiselect_display.dart';

class DownloadsPage extends StatefulWidget {
  DownloadsPage({Key key}) : super(key: key);

  @override
  _DownloadsPageState createState() => _DownloadsPageState();
}

class _DownloadsPageState extends State<DownloadsPage> {
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
              //_filterButtonsRow(),
              _selectedMessages.length > 0
                ? MultiSelectDisplay(
                  selectedMessages: _selectedMessages,
                  onDeselectAll: _deselectAll,
                )
                : _filterButtonsRow(model.sortDownloads),
              _messageCountAndSearch(
                context: context,
                total: model.totalDownloadsCount,
                played: model.playedDownloadsCount,
              ),
              _filteredList(context, model)
            ],
          ),
        );
      },
    );
  }

  Widget _filterButtonsRow(Function sortDownloads) {
    return Container(
      padding: EdgeInsets.only(top: 6.0, bottom: 5.0),
      child: Row(
        children: [
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(4, (index) {
                List<String> _categories = ['All', 'Unplayed', 'Played', 'Queue'];
                return _filterButton(
                  text: _categories[index],
                  selected: _filter == _categories[index],
                  onPressed: () {
                    setState(() {
                      _filter = _categories[index];
                      if (_filter == 'Queue') {
                        _searchTerm = '';
                        _searchOpen = false;
                      }
                    });
                  }
                );
              }),
            ),
          ),
          _sortActions(sortDownloads),
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
        padding: EdgeInsets.symmetric(horizontal: 10.0, vertical: 10.0),
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

  Widget _sortActions(Function sortDownloads) {
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
              text: 'Sort Newest to Oldest',
            ),
            _listAction(
              value: 1,
              text: 'Sort Oldest to Newest',
            ),
            _listAction(
              value: 2,
              text: 'Sort by Speaker A-Z',
            ),
            _listAction(
              value: 3,
              text: 'Sort by Speaker Z-A',
            ),
            _listAction(
              value: 4,
              text: 'Sort by Title A-Z',
            ),
            _listAction(
              value: 5,
              text: 'Sort by Title Z-A',
            ),
            _listAction(
              value: 6,
              text: 'Filter by Topic or Speaker'
            ),
          ];
        },
        onSelected: (value) {
          switch(value) {
            case 0:
              sortDownloads(
                orderBy: 'downloadedat',
                ascending: false,
              );
              break;
            case 1:
              sortDownloads(
                orderBy: 'downloadedat',
                ascending: true,
              );
              break;
            case 2:
              sortDownloads(
                orderBy: 'speaker',
                ascending: true,
              );
              break;
            case 3:
              sortDownloads(
                orderBy: 'speaker',
                ascending: false,
              );
              break;
            case 4:
              sortDownloads(
                orderBy: 'title',
                ascending: true,
              );
              break;
            case 5:
              sortDownloads(
                orderBy: 'title',
                ascending: false,
              );
              break;
            case 6:
              _toggleSearch();
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
          countDisplay = '$total Downloaded Message';
          if (total > 1) {
            countDisplay += 's';
          }
        }
        break;
      case 'Unplayed':
        if (total - played > 0) {
          countDisplay = '${total - played} Unplayed Download';
          if (total - played > 1) {
            countDisplay += 's';
          }
        }
        break;
      case 'Played':
        if (played > 0) {
          countDisplay = '$played Played Download';
          if (played > 1) {
            countDisplay += 's';
          }
        }
        break;
      case 'Queue':
        countDisplay = '';
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

    if (_filter == 'Queue') {
      return Container();
    }

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
          _searchOpen ? GestureDetector(
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 4.0, vertical: 4.0),
              color: Theme.of(context).backgroundColor.withOpacity(0.01),
              width: 38.0,
              child: Icon(CupertinoIcons.xmark_circle,
                size: 30.0,
                color: Theme.of(context).accentColor,
              ),
            ),
            onTap: _toggleSearch,
          )
          : Container(),
          /*GestureDetector(
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
          ),*/
        ],
      ),
    );
  }

  Widget _filteredList(BuildContext context, MainModel model) {
    List<Message> messageList;
    String emptyMessage = '';
    switch(_filter) {
      case 'All':
        messageList = model.downloads;
        emptyMessage = 'If you download any messages, they will appear here';
        break;
      case 'Unplayed':
        messageList = model.unplayedDownloads;
        emptyMessage = 'Any unplayed downloads will appear here';
        break;
      case 'Played':
        messageList = model.playedDownloads;
        emptyMessage = 'Any played downloads will appear here';
        break;
      case 'Queue':
        messageList = [];
        emptyMessage = 'Download queue is empty';
        break;
      default:
        messageList = model.downloads;
    }

    if (_filter == 'Queue') {
      return _queueDisplay(context, model, emptyMessage);
    }

    List<Message> filteredMessageList = filterMessageList(
      messages: messageList,
      searchTerm: _searchTerm,
    );

    if (messageList.length < 1) {
      return Expanded(
        child: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 150.0),
          child: model.downloadsLoading 
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
            child: model.downloadsLoading  
              ? CircularProgressIndicator()
              : Text('No downloads match that search filter',
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
              if (model.reachedEndOfDownloadsList) {
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
            if (index + Constants.MESSAGE_LOADING_BATCH_SIZE / 2 >= messageList.length && !model.reachedEndOfDownloadsList) {
              model.loadDownloadedMessagesFromDB();
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

  Widget _queueDisplay(BuildContext context, MainModel model, String emptyMessage) {
    List<Widget> listItems = [];
    if (model.currentlyDownloading.length > 0 || model.downloadQueue.length > 0) {
      listItems.add(_downloadQueueActions(
        context: context,
        paused: model.downloadsPaused,
        pauseReason: model.downloadPauseReason,
        onPause: model.pauseDownloadQueue,
        onResume: model.unpauseDownloadQueue,
      ));
    }
    if (model.currentlyDownloading.length > 0) {
      listItems.add(_listSectionTitle('Downloading (${model.currentlyDownloading.length})'));
      model.currentlyDownloading.forEach((task) {
        listItems.add(MessageCard(
          message: task?.message,
          selected: false,
          onSelect: null,
          isDownloading: true,
          downloadTask: task,
          onCancelDownload: () { model.cancelDownload(task); },
        ));
      });
    }
    if (model.downloadQueue.length > 0) {
      listItems.add(_listSectionTitle('Queue (${model.downloadQueue.length})'));
      model.downloadQueue.forEach((task) {
        listItems.add(MessageCard(
          message: task?.message,
          selected: false,
          onSelect: null,
          isDownloading: true,
          downloadTask: task,
          onCancelDownload: () { model.cancelDownload(task); },
        ));
      });
    }

    if (listItems.length < 1) {
      return Expanded(
        child: Container(
          alignment: Alignment.topCenter,
          padding: EdgeInsets.only(top: 150.0),
          child: model.downloadsLoading 
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
          itemCount: listItems.length + 1,
          itemBuilder: (context, index) {
            if (index >= listItems.length) {
              return SizedBox(height: 250.0); 
            }
            return listItems[index];
          },
        ),
      ),
    );
  }

  Widget _downloadQueueActions({BuildContext context, bool paused, PauseReason pauseReason, Function onPause, Function onResume}) {
    if (paused && pauseReason != null) {
      switch(pauseReason) {
        case PauseReason.noConnection:
          return Container(
            padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
            alignment: Alignment.center,
            child: Text('Downloads paused: no connection',
              textAlign: TextAlign.center,
              style: Theme.of(context).primaryTextTheme.headline4,
            ),
          );
          break;
        case PauseReason.connectionType:
          return Container(
            padding: EdgeInsets.symmetric(vertical: 18.0, horizontal: 8.0),
            alignment: Alignment.center,
            child: Text('Downloads paused: connect to WiFi or change download settings',
              textAlign: TextAlign.center,
              style: Theme.of(context).primaryTextTheme.headline4,
            ),
          );
          break;
        case PauseReason.user:
          break;
      }
    }
    IconData icon = paused ? CupertinoIcons.play_arrow : CupertinoIcons.pause;
    String text = paused ? 'Resume Downloads' : 'Pause Downloads';
    return Container(
      padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
      child: TextButton(
        onPressed: paused ? onResume : onPause,
        child: Container(
          alignment: Alignment.centerRight,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Icon(icon, 
                color: Theme.of(context).accentColor,
                size: 18.0,
              ),
              Container(
                padding: EdgeInsets.only(left: 3.0, top: 2.0),
                child: Text(text,
                  style: TextStyle(
                    color: Theme.of(context).accentColor,
                    fontSize: 15.0,
                  )
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _listSectionTitle(String title) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: Theme.of(context).accentColor.withOpacity(0.8),
        borderRadius: BorderRadius.circular(4.0),
      ),
      child: Text(title,
        style: TextStyle(
          color: Theme.of(context).primaryColor,
          fontSize: 22.0,
          fontWeight: FontWeight.w400,
        ),
      ),
    );
  }
}