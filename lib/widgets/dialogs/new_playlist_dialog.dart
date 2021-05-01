import 'package:flutter/material.dart';
import 'package:voices_for_christ/data_models/playlist_class.dart';
import 'package:voices_for_christ/database/local_db.dart';
import 'package:voices_for_christ/widgets/buttons/action_button.dart';

class NewPlaylistDialog extends StatefulWidget {
  NewPlaylistDialog({Key key}) : super(key: key);

  @override
  _NewPlaylistDialogState createState() => _NewPlaylistDialogState();
}

class _NewPlaylistDialogState extends State<NewPlaylistDialog> {
  String _title;
  List<String> _existingTitles = [];
  String _errorMessage = '';
  final db = MessageDB.instance;

  @override
  void initState() { 
    super.initState();
    loadCurrentPlaylistTitles();
  }

  Future<void> loadCurrentPlaylistTitles() async {
    List<Playlist> _existingPlaylists = await db.getAllPlaylistsMetadata();
    _existingTitles = _existingPlaylists.map((p) => p.title.toLowerCase()).toList();
  }

  Future<void> save(BuildContext context) async {
    bool _titleAlreadyUsed = titleIsDuplicated(_title);
    setErrorMessage(_titleAlreadyUsed);
    if (!_titleAlreadyUsed) {
      await db.newPlaylist(_title);
      Navigator.of(context).pop();
    }
  }

  bool titleIsDuplicated(String val) {
    return _existingTitles.indexOf(val.toLowerCase()) > -1;
  }

  void setErrorMessage(bool titleIsDuplicated) {
    if (titleIsDuplicated) {
      setState(() {
        _errorMessage = 'A playlist already exists with that title';
      });
    } else {
      setState(() {
        _errorMessage = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SimpleDialog(
      title: Text('New Playlist',
        style: TextStyle(
          color: Theme.of(context).accentColor,
        ),
      ),
      children: [
        _titleInput(),
        _errorDisplay(),
        _actionButtonRow(),
      ],
    );
  }

  Widget _titleInput() {
    return Container(
      width: MediaQuery.of(context).size.width,
      padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 20.0),
      child: TextField(
        style: TextStyle(
          color: Theme.of(context).accentColor,
          fontSize: 18.0,
        ),
        decoration: InputDecoration(
          hintText: 'Title'
        ),
        onChanged: (val) {
          setErrorMessage(titleIsDuplicated(val));
          _title = val;
        },
      ),
    );
  }

  Widget _errorDisplay() {
    if (_errorMessage == null || _errorMessage == '') {
      return Container();
    }
    return Container(
      padding: EdgeInsets.symmetric(vertical: 6.0, horizontal: 25.0),
      child: Text(_errorMessage,
        style: TextStyle(
          color: Theme.of(context).accentColor,
        )
      ),
    );
  }

  Widget _actionButtonRow() {
    return Container(
      padding: EdgeInsets.only(top: 14.0, right: 12.0, left: 12.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          ActionButton(
            text: 'Add',
            onPressed: () async {
              await save(context);
            },
          ),
          ActionButton(
            text: 'Cancel',
            onPressed: () {
              Navigator.of(context).pop();
            },
          ),
        ],
      ),
    );
  }
}