import 'dart:collection';
import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/download_class.dart';
import 'package:voices_for_christ/helpers/constants.dart' as Constants;
import 'package:scoped_model/scoped_model.dart';
import 'package:voices_for_christ/data_models/message_class.dart';
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
              //_filterButtonsRow(),
              _selectedMessages.length > 0
                ? MultiSelectDisplay(
                  selectedMessages: _selectedMessages,
                  onDeselectAll: _deselectAll,
                )
                : _filterButtonsRow(),
              _filteredList(model)
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

  Widget _filteredList(MainModel model) {
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
      default:
        messageList = model.downloads;
    }

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

    if (_filter == 'All') {
      List<Widget> listItems = [];
      if (model.currentlyDownloading.length > 0) {
        listItems.add(_listSectionTitle('Downloading'));
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
        listItems.add(_listSectionTitle('Queue'));
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

      if (model.currentlyDownloading.length > 0 || model.downloadQueue.length > 0) {
        listItems.add(_listSectionTitle('Downloaded'));
      }
      
      messageList.forEach((message) {
        listItems.add(MessageCard(
          message: message,
          selected: _selectedMessages.contains(message),
          onSelect: () {
            _toggleMessageSelection(message);
          },
        ));
      });

      return Expanded(
        child: Container(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 0.0),
            itemCount: listItems.length + 1,
            itemBuilder: (context, index) {
              if (index >= listItems.length) {
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
              if (index + Constants.MESSAGE_LOADING_BATCH_SIZE / 2 >= listItems.length && !model.reachedEndOfDownloadsList) {
                model.loadDownloadedMessagesFromDB();
              }
              return listItems[index];
            },
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

  Widget _listSectionTitle(String title) {
    return Container(
      alignment: Alignment.center,
      padding: EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).accentColor.withOpacity(1.0),
            width: 1.0,
          )
        )
      ),
      child: Text(title,
        style: Theme.of(context).primaryTextTheme.headline2,
      ),
    );
  }
}